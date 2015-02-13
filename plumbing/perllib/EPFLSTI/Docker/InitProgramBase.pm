#!/usr/bin/perl -w

package EPFLSTI::Docker::InitProgramBase;

use strict;

=head1 NAME

EPFLSTI::Docker::InitProgramBase - Abstract base class for the tasks of init.pl

=cut

use base 'IO::Async::Notifier';

=head1 DESCRIPTION

=head2 Attributes

=head3 $self->{process}

Is assumed to have a ->process_name method à la
L<EPFLSTI::Async::Process/process_name>

=head3 $self->{future}

The continuation of this command, as a L<Future> object.

=head2 Methods

=head3 start ($loop, $command, @args)

Abstract, no implementation in superclass.

=head3 pid ()

=head3 process_name ()

=head3 process_name ($newval)

Delegated to $self->{process}.

=cut

sub pid {
  my $self = shift;
  return $self->{process}->pid;
}

sub process_name {
  my $self = shift;
  return $self->{process}->process_name(@_);
}


=head3 _fatal ($msg)

Ensure that init.pl cares about $msg.

If a live L<Future> instance is present in $self->{future}, terminate
it with an error. Otherwise, interrupt the main loop. In both cases,
use $msg as the error message.

=cut

sub _fatal {
  my ($self, $msg) = @_;

  if ($self->{future} and not $self->{future}->is_ready) {
    $self->{future}->fail($msg);
  } else {
    $self->loop->stop($msg);
  }
}

1;
