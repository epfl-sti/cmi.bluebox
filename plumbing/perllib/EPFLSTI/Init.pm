#!/usr/bin/perl -w

use strict;

=head1 NAME

EPFLSTI::Init - Support for writing the init.pl script

=head1 SYNOPSIS

  use IO::Async::Loop;
  use EPFLSTI::Init;

  my $loop = IO::Async::Loop;

  my $future = EPFLSTI::Init::DaemonProcess
     ->start($loop, "tincd", "--no-detach")
     ->when_ready(qr/Ready/)->then(sub {
    # Do something, return a Future
  });

=head1 DESCRIPTION

=cut

package EPFLSTI::Init::DaemonProcess;

use Future;
use IO::Async::Process;
use EPFLSTI::Docker::Log;

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

sub stop {
  my ($self) = @_;
  $self->_make_quiet();
  if ($self->{process}) {
    $self->{process}->kill("TERM");
  }
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
# perl -Iplumbing/perllib -Idevsupport/perllib plumbing/perllib/EPFLSTI/Init.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use Carp;
use FileHandle;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;

{
  # For some reason, the Carp backtrace logic doesn't work if this is kept in
  # the main package?
  package TestUtils;

  sub await_ok ($&;$) {
    my ($loop, $sub, $msg) = @_;

    my $timeout = 10;
    my $interval = 0.1;

    my $timedout = Carp::shortmess("await_ok timed out");

    my $done = undef;
    my $timer;
    $timer = IO::Async::Timer::Periodic->new(
      interval => $interval,
      on_tick => sub {
        $timeout -= $interval;
        if ($timeout <= 0) {
          Test::More::fail($timedout);
          $done = 0;
          $loop->stop();
          $timer->stop();
        } elsif ($sub->()) {
          Test::More::pass($msg);
          $done = 1;
          $loop->stop();
          $timer->stop();
        }
      });
    $timer->start();
    $loop->add($timer);
    my $runstatus = $loop->run();
    warn $runstatus if $runstatus;
    Test::More::ok(defined $done);
  }
}

BEGIN { *await_ok = \&TestUtils::await_ok; }

sub xtest {}

test "await_ok: positive" => sub {
  my $loop = new IO::Async::Loop;
  my $are_we_there_yet = 0;
  my $unused = $loop->delay_future(after => 1)->then(sub {
    $are_we_there_yet = 1;
  });
  await_ok $loop, sub {$are_we_there_yet}, "awaits ok";
};

test "EPFLSTI::Init::DaemonProcess: fire and forget" => sub {
  my $loop = new IO::Async::Loop;
  my $touched = My::Tests::Below->tempdir() . "/touched.1";
  my $daemon = EPFLSTI::Init::DaemonProcess->start(
    $loop, "sh", "-c", "sleep 1 && touch $touched && sleep 30");
  ok(! -f $touched);
  await_ok $loop, sub {-f $touched};
  $daemon->stop();
};

test "EPFLSTI::Init::DaemonProcess: expect message" => sub {
  my $loop = new IO::Async::Loop;
  my $done = 0;
  my $daemon = EPFLSTI::Init::DaemonProcess
    ->start($loop, "sh", "-c", "sleep 1 && echo Ready && sleep 30");
  my $unused_future = $daemon->when_ready(qr/Ready/)->then(sub {
        $done = 1;
  });
  await_ok $loop, sub { $done };
  $daemon->stop();
};

test "EPFLSTI::Init::DaemonProcess: dies, but not too often" => sub {
  my $loop = new IO::Async::Loop;
  my $failbudget_file = My::Tests::Below->tempdir() . "/failbudget";
  FileHandle->new($failbudget_file, "w")->print(3);
  my $daemon = EPFLSTI::Init::DaemonProcess
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


test "EPFLSTI::Init::DaemonProcess: dies too often" => sub {
  my $loop = new IO::Async::Loop;
  my $daemon = EPFLSTI::Init::DaemonProcess
    ->start($loop, "/bin/true");
  my $result = $loop->run();
  like $result, qr|/bin/true|;
  like $result, qr/failed too many times/;
};

test "EPFLSTI::Init::DaemonProcess: keeps dying after successful start"
=> sub {
  my $loop = new IO::Async::Loop;
  my $daemon = EPFLSTI::Init::DaemonProcess
    ->start($loop, "sh", "-c", "sleep 0.1; echo Ready");
  my $survived = 0;
  my $future = $daemon->when_ready(qr/Ready/)->then(sub {
        warn "Ready";
        return $loop->delay_future(after => 2);
  })->then(sub {
        $survived = 1;
  });
  my $result = $loop->run();
  like $result, qr/failed too many times/;
  is $survived, 0;
};

# In case of process leak, will block here.
while (wait() != -1) {};
1;
