#!/usr/bin/perl -w

package EPFLSTI::Docker::Init::Command;

use strict;

=head1 NAME

EPFLSTI::Docker::Init::Command - Commands run by the init.pl script

=head1 SYNOPSIS

  use IO::Async::Loop;
  use EPFLSTI::Docker::Init::Command;

  my $loop = IO::Async::Loop;

  my $future = EPFLSTI::Docker::Init::Command
     ->start($loop, "mkdir", "/tmp/foo")
     ->when_done->then(sub {
    # Do something, return a Future
  });

=head1 DESCRIPTION

This is a lot like L<EPFLSTI::Async::Process>, with the following
features on top:

=over 4

=item *

Leaner API with L<Future>s, more geared towards using directly in
init.pl than the usual $loop->add() based stuff.

=item *

Control exit codes: code 0 makes the future ->done, other codes cause
a ->fail

=back

=cut

use base 'EPFLSTI::Docker::Init::Base';

use Future;
use POSIX qw(WIFEXITED WEXITSTATUS);
use EPFLSTI::Async::Process;
use EPFLSTI::Docker::Log;

=head2 start ($loop, $command, @args)

Start the command.

Unless L</when_done> is called afterwards, this is a "fire and forget"
operation (similar to the & operator in the shell).

=cut

sub start {
  my ($class, $loop, @command) = @_;

  my $self = bless {
    process_name => join(" ", @command),
  }, $class;

  $self->{process} = EPFLSTI::Async::Process->new(
      command => [@command],
      on_setup_failed => $self->_capture_weakself('_on_setup_failed'),
      on_exit => $self->_capture_weakself('_on_exit'));
  $loop->add($self);

  return $self;
}

=head2 when_done

Returns a L<Future> that will be ->done if and when the command exits
successfully, and will ->fail if and when the command exits with a
nonzero status.

=cut

sub when_done {
  my ($self) = @_;
  return $self->{future} = Future->new();
}

sub _on_setup_failed {
  my $self = shift or return;  # Weakened self
  my (undef, $error, $dollarbang) = @_;
  my $name = $self->process_name;
  $self->_fatal("Cannot start $name: $error: $dollarbang"),
}

sub _on_exit {
  my $self = shift or return;  # Weakened self
  return unless $self->{future};  # No future

  my (undef, $exitcode) = @_;

  if (! $exitcode) {
    $self->{future}->done;
  } else {
    my $status = $self->_exit_code_to_string($exitcode);
    my $name = $self->process_name;
    $self->_fatal("$name failed with $status");
  }
}

1;
