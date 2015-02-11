#!/usr/bin/perl -w

package EPFLSTI::Docker::DaemonProcess;

use strict;

=head1 NAME

EPFLSTI::Docker::DaemonProcess - Support for writing the init.pl script

=head1 SYNOPSIS

  use IO::Async::Loop;
  use EPFLSTI::Docker::DaemonProcess;

  my $loop = IO::Async::Loop;

  my $future = EPFLSTI::Docker::DaemonProcess
     ->start($loop, "tincd", "--no-detach")
     ->when_ready(qr/Ready/)->then(sub {
    # Do something, return a Future
  });

=head1 DESCRIPTION

=cut

use Future;
use IO::Async::Process;
use EPFLSTI::Docker::Log;

=head2 start ($loop, @command)

Start @command on the event loop $loop.

  my $daemon = EPFLSTI::Docker::DaemonProcess->start(
    $loop, "tincd", "--no-detach");

The command will start as soon as C<$loop> has a chance to run (i.e.
C<< $loop->run() >> or returning from an event handler). Its standard
input and output will be set up using L<EPFLSTI::Docker::Log/open>.

The command is allotted a failure budget of $daemon->{max_restarts}
times (defaults to 4). If it blows through it, failure will be
propagated either by failing the L</when_ready> future (if it isn't
resolved yet), or by calling C<< $loop->stop($msg) >> with $msg
containing the text "failed too many times". That is, it is
purposefully not possible to ignore a flapping daemon, unless it is
voluntarily L</stop>ped.

=cut

sub start {
  my ($class, $loop, @command) = @_;
  my $self = bless {
    name => join(" ", @command),
    command => [@command],
    max_restarts => 4,
    loop => $loop,
  }, $class;
  $self->_start_process_on_loop();
  return $self;
}

sub when_ready {
  my ($self, $running_re, $timeout) = @_;
  if (! defined $timeout) {
    $timeout = 30;
  }

  my $when = Future->new();

  $self->{_on_read} = sub {
    my ($bufref) = @_;
    if ($$bufref =~ $running_re) {
      $when->done($$bufref);
      $$bufref = "";
    };
  };

  $self->{on_too_many_restarts} = sub {
    $when->fail(shift);
  };

  $self->{ready_timeout} = $self->{loop}
    ->delay_future(after => $timeout)
    ->then(sub {
      # $when is still live, otherwise _make_quiet would have cancelled us.
      $when->fail("Timeout waiting for $self->{name} to start");
      delete $self->{loop};  # Prevent cyclic garbage
    });

  return $when->then(sub {$self->_make_quiet; $when},
                     sub {$self->_make_quiet; $when});
}

sub _make_quiet {
  my ($self) = @_;
  delete $self->{_on_read};
  delete $self->{on_too_many_restarts};
  if ($self->{ready_timeout}) {
    $self->{ready_timeout}->cancel();
  };
}

=head2 stop()

Stop the daemon and all pending conditions (start timeout, watching
ready messages, restart logic etc.)

=cut

sub stop {
  my ($self) = @_;
  $self->_make_quiet();
  if ($self->{process}) {
    $self->{process}->kill("TERM");
  }
  delete $self->{loop};  # Prevent cyclic garbage, unwanted restarts
}

sub _start_process_on_loop {
  my ($self) = @_;
  do { warn "No loop"; return } unless (my $loop = $self->{loop});

  $self->{process} = new IO::Async::Process(
    command => $self->{command},
    stdin => { from => "" },
    stdout => { via => "pipe_read" },
    stderr => { via => "pipe_read" },
    on_finish => sub {
      if ($self->{max_restarts}--) {
        $self->_start_process_on_loop();
      } else {
        my $msg = $self->{name} . " failed too many times";
        msg $msg;
        delete $self->{loop};  # Prevent cyclic garbage
        if ($self->{on_too_many_restarts}) {
          $self->{on_too_many_restarts}->($msg);
        } else {
          # A flapping daemon causes init.pl to stop, even if ->when_ready()
          # has succeeded already.
          $loop->stop($msg);
        }
      }});

  foreach my $stream ($self->{process}->stdout(), $self->{process}->stderr()) {
    $stream->configure(on_read => sub {
      my ($stream, $buffref, $eof) = @_;
      if ($self->{_on_read}) {
        $self->{_on_read}->($buffref);
      } else {
        $$buffref = "";
      }
      return 0;
    });
  }

  $loop->add($self->{process});
}


require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Docker/DaemonProcess.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use Carp;
use FileHandle;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;
use EPFLSTI::Async::Tests qw(await_ok);

sub xtest {}

test "EPFLSTI::Docker::DaemonProcess: fire and forget" => sub {
  my $loop = new IO::Async::Loop;
  my $touched = My::Tests::Below->tempdir() . "/touched.1";
  my $daemon = EPFLSTI::Docker::DaemonProcess->start(
    $loop, "sh", "-c", "sleep 1 && touch $touched && sleep 30");
  ok(! -f $touched);
  await_ok $loop, sub {-f $touched};
  $daemon->stop();
};

test "EPFLSTI::Docker::DaemonProcess: expect message" => sub {
  my $loop = new IO::Async::Loop;
  my $done = 0;
  my $daemon = EPFLSTI::Docker::DaemonProcess
    ->start($loop, "sh", "-c", "sleep 1 && echo Ready && sleep 30");
  my $unused_future = $daemon->when_ready(qr/Ready/)->then(sub {
        $done = 1;
  });
  await_ok $loop, sub { $done };
  $daemon->stop();
};

test "EPFLSTI::Docker::DaemonProcess: dies, but not too often" => sub {
  my $loop = new IO::Async::Loop;
  my $failbudget_file = My::Tests::Below->tempdir() . "/failbudget";
  FileHandle->new($failbudget_file, "w")->print(3);
  my $daemon = EPFLSTI::Docker::DaemonProcess
    ->start($loop, $^X, "-we", <<'SCRIPT', $failbudget_file);
use strict;
use FileHandle;
warn "[$$] Starting";
open(FAIL_BUDGET, "<", $ARGV[0]) or die "Cannot open $ARGV[0]";
my $failbudget = <FAIL_BUDGET>;
warn "[$$] Remaining fail budget: $failbudget";
if ($failbudget <= 0) {
   warn "[$$] Ready";
   sleep(30);
} else {
   open(FAIL_BUDGET, ">", $ARGV[0]);
   print FAIL_BUDGET ($failbudget - 1);
}
SCRIPT
  my $done = 0;
  my $unused_future = $daemon->when_ready(qr/Ready/)->then(sub {
        $done = 1;
  });
  await_ok $loop, sub {$done}, "Progresses to ready state";
  is(FileHandle->new($failbudget_file, "r")->getline(), 0);
  $daemon->stop();
};


test "EPFLSTI::Docker::DaemonProcess: dies too often" => sub {
  my $loop = new IO::Async::Loop;
  my $daemon = EPFLSTI::Docker::DaemonProcess
    ->start($loop, "/bin/true");
  my $result = $loop->run();
  like $result, qr|/bin/true|;
  like $result, qr/failed too many times/;
};

test "EPFLSTI::Docker::DaemonProcess: keeps dying after successful start"
=> sub {
  my $loop = new IO::Async::Loop;
  my $daemon = EPFLSTI::Docker::DaemonProcess
    ->start($loop, "sh", "-c", "sleep 0.1; echo Ready");
  my $survived = 0;
  my $future = $daemon->when_ready(qr/Ready/)->then(sub {
        return $loop->delay_future(after => 2);
  })->then(sub {
        $survived = 1;
  });
  my $result = $loop->run();
  like $result, qr/failed too many times/;
  is $survived, 0;
};

# If your test waits 30 seconds here, you are leaking processes.
while (wait() != -1) {};
1;
