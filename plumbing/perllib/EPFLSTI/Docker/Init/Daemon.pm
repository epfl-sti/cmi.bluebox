#!/usr/bin/perl -w

package EPFLSTI::Docker::Init::Daemon;

use strict;

=head1 NAME

EPFLSTI::Docker::Init::Daemon - Daemons for the init.pl script

=head1 SYNOPSIS

  use IO::Async::Loop;
  use EPFLSTI::Docker::Init::Daemon;

  my $loop = IO::Async::Loop;

  my $future = EPFLSTI::Docker::Init::Daemon
     ->start($loop, "tincd", "--no-detach")
     ->when_ready(qr/Ready/)->then(sub {
    # Do something, return a Future
  });

=head1 DESCRIPTION

This is a lot like L<EPFLSTI::Async::Process>, with the following
features on top:

=over 4

=item *

Automated flakyness monitoring and recovery: an
EPFLSTI::Docker::Init::Daemon simply is not supposed to exit.

=item *

Leaner API with L<Future>s, more geared towards using directly in
init.pl than the usual $loop->add() based stuff.

=back

=cut

use base 'EPFLSTI::Docker::Init::Base';

use Future;
use EPFLSTI::Async::Process;
use EPFLSTI::Docker::Log;

=head2 start ($loop, @command)

Start @command on the event loop $loop.

  my $daemon = EPFLSTI::Docker::Init::Daemon->start(
    $loop, "tincd", "--no-detach");

The command will start as soon as C<$loop> has a chance to run (i.e.
C<< $loop->run() >> or after returning from the current event
handler). Its standard input and output will be set up to files as per
the L<EPFLSTI::Docker::Log> convention.

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
    command => [@command],
    max_restarts => 4,
  }, $class;
  $loop->add($self);
  $self->_start_process_on_loop();
  return $self;
}

sub when_ready {
  my ($self, $running_re, $timeout) = @_;
  if (! defined $timeout) {
    $timeout = 30;
  }

  my $when = $self->{future} = Future->new();

  $self->{ready_line_regexp} = $running_re;
  $self->_reconfigure_process();

  $self->{ready_timeout} = $self->loop
    ->delay_future(after => $timeout)
    ->then(sub {
      # $when is still live, otherwise _make_quiet would have cancelled us.
      my $name = $self->process_name;
      $when->fail("Timeout waiting for $name to start");
    });

  return $when->then(sub {$self->_make_quiet; $when},
                     sub {$self->_make_quiet; $when});
}

sub _reconfigure_process {
  my ($self) = @_;
  $self->{process}->configure(
    ready_line_regexp => $self->{ready_line_regexp},
    on_ready => $self->_capture_weakself('_on_ready'),
   );
}

sub _make_quiet {
  my ($self) = @_;
  delete $self->{ready_line_regexp};
  $self->_reconfigure_process();
  if ($self->{ready_timeout}) {
    $self->{ready_timeout}->cancel();
  };
  if ($self->{future}) {
    $self->{future}->cancel();
  }
}

=head2 stop ()

Stop the daemon and all pending conditions (start timeout, watching
ready messages, restart logic etc.)

=cut

sub stop {
  my ($self) = @_;
  $self->_make_quiet();
  if ($self->{process}) {
    $self->{process}->kill("TERM");
  }
}

=begin internals

=head2 _start_process_on_loop ()

Create an L<EPFLSTI::Async::Process> instance and put it on $self->loop.

May be called recursively from L</_on_daemon_exited>, although we hope
it won't be.

=cut

sub _start_process_on_loop {
  my ($self) = @_;
  do { warn "No loop"; return } unless (my $loop = $self->loop);

  if ($self->{process}) {
    $self->remove_child(delete $self->{process});
  }

  $self->{process} = new EPFLSTI::Async::Process(
    command => $self->{command},
    on_setup_failed => sub {
      my (undef, $error, $dollarbang) = @_;
      my $name = $self->process_name;
      $self->_fatal("Cannot start $name: $error: $dollarbang"),
    },
    on_exit => $self->_capture_weakself('_on_daemon_exited'));
  $self->_reconfigure_process();

  $self->add_child($self->{process});
}

=head2 _on_ready ($process, $matching_line, $file)

=cut

sub _on_ready {
  my $self = shift or return;  # Weak ref to $self
  my (undef, $matching_line, $path) = @_;
  my $name = $self->process_name;
  chomp($matching_line);
  msg qq'Daemon "$name" looks ready - Seen this line in $path: $matching_line';
  $self->{future}->done();
}

=head2 _on_daemon_exited ($exitcode)

Bad news are afoot.

Restart with L</_start_process_on_loop> if within failure budget,
otherwise signal the error, up to and including L</_fatal> – An
unmanaged, flapping daemon is fatal, even if L</when_ready> has
succeeded already.

=cut

sub _on_daemon_exited {
  my $self = shift or return;  # Gets a weak ref to self
  my (undef, $exitcode) = @_;
  my $name = $self->process_name;
  if (--$self->{max_restarts} >= 0) {
    my $status = $self->_exit_code_to_string($exitcode);
    msg "$name exited with $status, restarting " .
      "($self->{max_restarts} attempt(s) remaining)";
    $self->_start_process_on_loop();
    return;
  }

  my $msg = "$name failed too many times";
  msg $msg;
  if (my $cb = $self->can_event("on_too_many_restarts")) {
    $cb->($self, $self->{process});
  } else {
    $self->_fatal($msg);
  }
}

=end internals

=cut

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Docker/Init/Daemon.pm

__END__

use Test::More qw(no_plan);
use Test::Group;
use IO::Async::Test;

use Carp;

use FileHandle;
use File::Spec::Functions qw(catfile);

use IO::Async::Loop;
use IO::Async::Timer::Periodic;

use EPFLSTI::Docker::Log;

mkdir(my $logdir = catfile(My::Tests::Below->tempdir, "log"))
  or die "mkdir: $!";

EPFLSTI::Docker::Log::log_dir($logdir);

test "EPFLSTI::Docker::Init::Daemon: fire and forget" => sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);
  my $touched = My::Tests::Below->tempdir() . "/touched.1";
  my $daemon = EPFLSTI::Docker::Init::Daemon->start(
    $loop, "sh", "-c", "sleep 1 && touch $touched && sleep 30");
  ok(! -f $touched);
  wait_for {-f $touched};
  $daemon->stop();
};

test "EPFLSTI::Docker::Init::Daemon: expect message" => sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);
  my $done = 0;
  my $daemon = EPFLSTI::Docker::Init::Daemon
    ->start($loop, "sh", "-c", "sleep 1 && echo Ready && sleep 30");

  my $unused_future = $daemon->when_ready(qr/Ready/)->then(sub {
        $done = 1;
  });
  wait_for { $done };
  pass("Ready seen");
  $daemon->stop();
};

test "EPFLSTI::Docker::Init::Daemon: dies, but not too often" => sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);
  my $failbudget_file = My::Tests::Below->tempdir() . "/failbudget";
  FileHandle->new($failbudget_file, "w")->print(3);
  my $daemon = EPFLSTI::Docker::Init::Daemon
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
   close FAIL_BUDGET;
   exit 4;
}
SCRIPT
  my $done = 0;
  my $unused_future = $daemon->when_ready(qr/Ready/)->then(sub {
        $done = 1;
  });
  wait_for {$done};
  pass("Progresses to ready state");
  is(FileHandle->new($failbudget_file, "r")->getline(), 0);
  $daemon->stop();
};


test "EPFLSTI::Docker::Init::Daemon: dies too often" => sub {
  my $loop = new_builtin IO::Async::Loop;
  my $daemon = EPFLSTI::Docker::Init::Daemon
    ->start($loop, "true");
  my $result = $loop->run();
  like $result, qr|true|;
  like $result, qr/failed too many times/;
};

test "EPFLSTI::Docker::Init::Daemon: keeps dying after successful start"
=> sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);
  my $soapbox = My::Tests::Below->tempdir() . "/soapbox";
  FileHandle->new($soapbox, "w")->close;
  ok(-f $soapbox);

  my $daemon = EPFLSTI::Docker::Init::Daemon
    ->start($loop, $^X, "-we",
            "use strict; if (-f '$soapbox') { warn 'Ready\n'; sleep(30) } else { sleep 0.1 }");
  my $future = $daemon
    ->when_ready(qr/Ready/)
    ->then(sub { return Future->done("DONE") });

  wait_for { eval { $future->get } };
  is($future->get, "DONE");

  # Kick the soapbox from under the process
  unlink $soapbox;

  my $pid = $daemon->pid;
  kill HUP => $pid or die $!;
  # Do *NOT* waitpid, or $loop would be none the wiser!

  # This made the Perl scriptlet flaky; the loop should now exit
  my $result = $loop->run();
  like $result, qr/failed too many times/;
};

# If the test waits 30 seconds here, it means we are leaking processes.
while (wait() != -1) {};
1;
