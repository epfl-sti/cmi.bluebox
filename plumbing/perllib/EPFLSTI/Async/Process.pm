#!/usr/bin/perl -w

package EPFLSTI::Async::Process;

use strict;
use warnings;

use constant _ASSERT_CHECKS => 1;

=head1 NAME

EPFLSTI::Async::Process - A fork()ed process to monitor asynchronously

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use IO::Async::Loop;
  use EPFLSTI::Async::Process;

  my $loop = new IO::Async::Loop;
  my $process = new EPFLSTI::Async::Process(
    command => [@command_and_args],
    log_files => [$extra_log_file],  # stdout / stderr are implicit
    ready_line_regexp => qr/Ready|Listening|Serving/i,
    on_ready => \&on_ready_callback,
    on_exit => \&on_exit_callback,
    on_exec_failed => \&on_exec_failed,
  );
  $loop->add($process);

=for My::Tests::Below "synopsis" end

  $loop->run();

  # Later, in a callback...
  $process->kill("TERM");


=head1 DESCRIPTION

An instance represents a process that may be run and monitored
asynchronously (using L<IO::Async>). The intent is to run processes
from a /sbin/init-like written in Perl.

Both one-shot processes (that do something and exit), and daemons
(that are expected to stay up) can be tackled with this module;
however, for the latter consider using
L<EPFLSTI::Docker::DaemonProcess> instead that handles all the restart
/ flapping logic.

=cut

use base qw( IO::Async::Notifier );

use Set::Scalar;

use Carp;

use File::Basename qw(basename);
use POSIX qw(WEXITSTATUS setsid);

use IO::Async::Process;

use EPFLSTI::Async::NewFileStream;
use EPFLSTI::Docker::Log;

sub _init {
  my $self = shift;
  $self->{_watched_files} = {};
}

sub configure {
  my $self = shift;
  my %params = @_;

  if (exists $params{command}) {
    croak "Too late to change command" if defined $self->pid;
    croak "command must be an ARRAY reference"
      unless ref $params{command} eq "ARRAY";
    $self->{command} = delete $params{command};
    $self->process_name(basename($self->{command}->[0]))
      unless $self->process_name;

    if ($self->{process}) {
      $self->remove_child($self->{process});
    }
    # ->process_name (used in the sub below) may still change until
    # ->_add_to_loop(), but not between then and fork().
    $self->{process} = IO::Async::Process->new(
      setup => [
        stdin  => [ "open", "<", File::Spec->devnull ],
        stdout => [ "open", ">>", EPFLSTI::Docker::Log::logfile_path(
          $self->process_name, $$, ".stdout") ],
        stderr => [ "open", ">>", EPFLSTI::Docker::Log::logfile_path(
          $self->process_name, $$, ".stderr") ],
        chdir => File::Spec->rootdir,
       ],
      code => sub {
        # L<IO::Async::ChildManager> handles the entire daemon
        # ritual, except setsid() and the double fork(). We don't
        # want the latter; we need to wait() on the children.
        # (Besides, we are probably PID 1 so it wouldnt't work.)

        die "Cannot detach from controlling terminal" if setsid() < 0;
        exec(@{$self->{command}}) or
          die "__CANNOT_EXEC__";
      },
      on_finish => $self->_capture_weakself( sub {
         my $self = shift or return;
         $self->_on_process_exit(@_);
       }),
      on_exception => $self->_capture_weakself( sub {
         my $self = shift or return;
         my (undef, $exn, $errno, $exitcode) = @_;

         if ($exn && $exn =~ m/^__CANNOT_EXEC__/) {
           $self->_on_exec_failed($errno);
         } elsif (length $exn) {
           $self->_fatal({
             message => "Forked process died before exec()",
             errno => $errno,
             exception => $exn
            });
         } else {
           $self->_fatal({
             message => "Forked process exit()ed before exec()",
             exitcode => $exitcode
            });
         }
       }),
    );
    $self->add_child($self->{process});
  }

  if (exists $params{interval}) {
    $self->{interval} = delete $params{interval};
    foreach my $filestream (values %{$self->{_watched_files}}) {
      $filestream->configure(interval => $self->{interval});
    }
  }

  if (exists $params{log_files}) {
    $self->_update_watchers(delete $params{log_files});
  }

  if (exists $params{ready_line_regexp}) {
    $self->{ready_line_regexp} = delete $params{ready_line_regexp};
    $self->_update_watchers();
  }

  if (exists $params{on_ready}) {
    $self->{on_ready} = delete $params{on_ready};
    $self->_update_watchers();
  }

  if (exists $params{on_exit}) {
    $self->{on_exit} = delete $params{on_exit};
  }

  if (exists $params{on_exec_failed}) {
    $self->{on_exec_failed} = delete $params{on_exec_failed};
  }

  $self->SUPER::configure(%params);
}

=head2 process_name

=head2 process_name ($newval)

Get or set the name of the process that will be used for the log files.

=cut

sub process_name {
  my $self = shift;
  if (@_) {
    $self->{process_name} = $_[0];
  } else {
    return $self->{process_name};
  }
}

=head2 stdout_filename

=head2 stder_filename

Return the paths to the respective log files, which are created
automatically and watched by default for the C<ready_line_regexp> (see
L</configure>).

=cut

sub stdout_filename {
  my $self = shift;
  return unless defined(my $pid = $self->pid);
  return EPFLSTI::Docker::Log::logfile_path(
     $self->process_name, $self->pid, ".stdout");
}

sub stderr_filename {
  my $self = shift;
  return unless defined(my $pid = $self->pid);
  return EPFLSTI::Docker::Log::logfile_path(
     $self->process_name, $self->pid, ".stderr");
}

=head2 pid

=head2 kill

=head2 is_runnning

=head2 is_exited

=head2 exitstatus

=head2 exception

=head2 errno

=head2 errstr

Delegated to the underlying L<IO::Async::Process> object.

=cut

sub pid {
  my $self = shift;
  return unless ($self and defined(my $process = $self->{process}));
  return $process->pid;
}

foreach my $delegate (qw(kill is_running is_exited exitstatus
                         exception errno errstr)) {
  my $delegated_method = sub {
    my $self = shift;
    croak "No process!" unless $self->{process};
    return $self->{process}->can($delegate)->($self->{process}, @_);
  };
  no strict "refs";
  *{"EPFLSTI::Async::Process::${delegate}"} = $delegated_method;
}

=begin internals

=head2 _add_to_loop

Overridden to enforce mandatory ->configure() parameters as usual, and
also to add watchers for the .stdout and .stderr as soon as the PID is
known.

=cut

sub _add_to_loop {
  my ($self, $loop) = @_;
  die "Must set a command" unless $self->{process};
  $self->SUPER::_add_to_loop($loop);
  # We are "in the loop", and our ->children will soon be too. When
  # $self->{process} gets added it will fork(), and then we will know
  # the PID and hence the stdout and stderr paths:
  $loop->later(sub { $self->_update_watchers });
}

=head2 _needs_watching

Whether there is any point in setting up the armada of
L<EPFLSTI::Async::NewFileStream> instances.

=cut

sub _needs_watching {
  my $self = shift;
  return ($self->{ready_line_regexp} && $self->can_event("on_ready"));
}

=head2 _update_watchers

Start or stop the watchers on L</stdout_filename> and
L</stderr_filename>, depending on the current process and
L</configure> state.

=cut

sub _update_watchers {
  my ($self, $new_watchlist_arrayref) = @_;

  my $old_watchlist = Set::Scalar->new(keys %{$self->{_watched_files}});

  my $new_watchlist;
  if ($new_watchlist_arrayref) {
    # Called from L</configure> with a new setting for log_files
    $new_watchlist = Set::Scalar->new(@$new_watchlist_arrayref);
  } else {
    # No changes requested - Yet some may be needed (e.g. if PID is
    # now known, see next few lines)
    $new_watchlist = $old_watchlist->clone();
  }
  if ($self->pid) {
    # Those are always watched
    $new_watchlist->insert($self->stdout_filename, $self->stderr_filename);
  }

  # Invariants to restore upon return: $self->{_watched_files} is to be
  # a hash where keys are filenames, and values are either instances
  # of IO::Async::FileStream (if $self->_needs_watching), or 1 (if
  # not). Added / removed IO::Async::FileStream's need to be passed to
  # ->add_child() / ->remove_child().
  foreach my $unwatched ($old_watchlist->
                           difference($new_watchlist)->elements) {
    my $obj_or_one = delete $self->{_watched_files};
    $self->remove_child($obj_or_one) if (ref $obj_or_one);
  }

  foreach my $watched ($new_watchlist->difference($old_watchlist)->elements) {
    $self->{_watched_files}->{$watched} = 1;
  }

  if (_ASSERT_CHECKS) {
    die "Discrepancy" unless Set::Scalar->new(keys %{$self->{_watched_files}})
      ->is_equal($new_watchlist);
  }

  foreach my $path (keys %{$self->{_watched_files}}) {
    my $activate = $self->_needs_watching;
    next unless ($activate xor ref($self->{_watched_files}->{$path}));
    if ($activate) {
      $self->add_child($self->{_watched_files}->{$path} =
          new EPFLSTI::Async::NewFileStream(
            ($self->{interval} ? (interval => $self->{interval}) : ()),
            filename => $path,
            on_read => $self->_capture_weakself( sub {
                my $self = shift or return;
                my (undef, $bufref) = @_;
                while( $$bufref =~ s/^(.*\n)// ) {
                  $self->_on_log_line($path, $1);
                }
                return 0;
              })));
    } else {
      $self->remove_child($self->{_watched_files}->{$path});
      $self->{_watched_files}->{$path} = 1;
    }
  }
}

=head2 _on_process_exit ($?)

=head2 _on_exec_failed ($!)

=cut

sub _on_process_exit {
  my ($self, $unused_process, $exitcode) = @_;
  if (my $cb = $self->can_event("on_exit")) {
    $cb->($exitcode);
  }
}

sub _on_exec_failed {
  my ($self, $error) = @_;
  if (my $cb = $self->can_event("on_exec_failed")) {
    $cb->($error);
  }
}

=head2 _on_log_line ($path, $line)

=cut

sub _on_log_line {
  my ($self, $path, $line) = @_;
  return unless $self->_needs_watching;
  if ($line =~ $self->{ready_line_regexp}) {
    $self->can_event("on_ready")->();
    delete $self->{ready_line_regexp};
    $self->_update_watchers();  # i.e. close them all
  }
}

=head2 _fatal ($exn_hash)

The behavior for fatal (programming) errors, for overriding in a
subclass. Stops the loop.

=cut

sub _fatal {
  my ($self, $exn) = @_;
  if (! ref($exn)) {
    warn $exn;
  } else {
    warn "$exn->{message}: $exn->{errno}";
  }
  $self->loop->stop($exn);
}

=end internals

=cut

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Async/Process.pm

__END__

use Test::More qw(no_plan);
use Test::Group;
use IO::Async::Test;

use Carp 'verbose';
use Errno;

use POSIX;

use FileHandle;
use File::Spec::Functions qw(catfile);

use EPFLSTI::Docker::Log;

mkdir(my $logdir = catfile(My::Tests::Below->tempdir, "log"))
  or die "mkdir: $!";

EPFLSTI::Docker::Log::log_dir($logdir);

my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");
$synopsis =~ s|new IO::Async::Loop|new_builtin IO::Async::Loop|g;

eval sprintf(<<'RUNNABLE_SYNOPSIS', $synopsis);

package Synopsis;

our (@command_and_args, $extra_log_file);

our $on_ready_callback = sub {};
our $on_exit_callback = sub {};
our $on_exec_failed_callback = sub {};

sub on_ready_callback { $on_ready_callback->(@_); }
sub on_exit_callback { $on_exit_callback->(@_); }
sub on_exec_failed_callback { $on_exec_failed_callback->(@_); }

sub run_synopsis {
%s
  return wantarray ? ($loop, $process) : $loop;
}

RUNNABLE_SYNOPSIS

test "synopsis" => sub {
  @Synopsis::command_and_args = ("sleep", "30");

  # This file will never be created; EPFLSTI::Async::Process shouldn't care.
  $Synopsis::extra_log_file = catfile($logdir, "sleep.log");

  $Synopsis::on_ready_callback = sub { fail "on_ready: too soon!" };
  $Synopsis::on_exit_callback = sub { fail "on_exit: too soon!" };
  $Synopsis::on_exec_failed_callback = sub {
    fail "on_exec_failed: not expected in this test"};
  my ($loop, $process) = Synopsis::run_synopsis();
  $process->configure(interval => 0.1);  # Speed up test
  testing_loop($loop);

  $loop->await($loop->delay_future(after => 0.2));
  pass("At first, nothing happens.");

  # EPFLSTI::Async::Process has no way to tell that the sleep command
  # isn't the one doing these writes:
  my $stderr_file = EPFLSTI::Docker::Log::logfile_path(
    "sleep", $process->pid, ".stderr");
  FileHandle->new($stderr_file, ">")->write("Read");
  $loop->await($loop->delay_future(after => 1.1));
  pass("Not quite ready yet.");

  my $ready;
  $Synopsis::on_ready_callback = sub { $ready = 1 };
  FileHandle->new($stderr_file, ">>")->write("y\n");
  wait_for {$ready};

  my $exitcode;
  $Synopsis::on_exit_callback = sub { $exitcode = shift };
  $process->kill("SIGHUP");
  wait_for {$exitcode};
  is $exitcode, POSIX::SIGHUP;
};

test "command that terminates normally" => sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);

  my $exitcode;

  my $process = new EPFLSTI::Async::Process(
    command => ["sh", "-c", "exit 42"],
    on_ready => sub { fail "Should not become ready" },
    on_exit => sub { $exitcode = shift },
    on_exec_failed => sub { "Should not fail exec" },
  );
  $loop->add($process);

  wait_for { $exitcode };
  is $exitcode, 42 << 8;
};

test "command that terminates with a signal" => sub {
  testing_loop(my $loop = new_builtin IO::Async::Loop);

  my $exitcode;

  my $process = new EPFLSTI::Async::Process(
    command => [$^X, "-e", 'kill HUP => $$'],
    on_ready => sub { fail "Should not become ready" },
    on_exit => sub { $exitcode = shift },
    on_exec_failed => sub { fail "Should not fail exec" },
  );
  $loop->add($process);

  wait_for { $exitcode };
  is $exitcode, POSIX::SIGHUP;
};

test "exec() fails" => sub {
  my $does_not_exist = "/zbin/falze";
  -f $does_not_exist and die "O RLY?";

  $main::stop_now = 1;
  testing_loop(my $loop = new_builtin IO::Async::Loop);

  my $dollarbang;
  my $process = new EPFLSTI::Async::Process(
    command => [$does_not_exist],
    on_ready => sub { fail "Should not become ready" },
    on_exit => sub { fail "Should not exit" },
    on_exec_failed => sub { $dollarbang = shift },
  );
  $loop->add($process);

  wait_for { $dollarbang };
  is((0 + $dollarbang), Errno::ENOENT);
  is("$dollarbang", POSIX::strerror(Errno::ENOENT));
};

# If the test waits 30 seconds here, it means we are leaking processes.
while (wait() != -1) {};
1;
