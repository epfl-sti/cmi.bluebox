#!/usr/bin/perl -w

package EPFLSTI::BlueBox::NOC;

use strict;

=head1 NAME

EPFLSTI::BlueBox::VPN - Model for the Blue Box NOC.

=cut

use IO::All;
use JSON;

use EPFLSTI::Docker::Paths;

BEGIN {
  *JSON_CONFIG = EPFLSTI::Docker::Paths->settable_srv_subpath("noc.json");
}

our $singleton;
sub the {
  my ($class) = @_;
  if (! $singleton) {
    $singleton = bless {}, $class;
  }
  return $singleton;
}

sub _config {
  my ($self) = @_;
  return ($self->{config} ||= from_json(io->file(JSON_CONFIG)->slurp));
}

sub hostname {
  my $self = shift;
  $self = $self->the unless ref($self);
  if (@_) {
    $self->_config->{hostname} = shift;
  } else {
    return $self->_config->{hostname};
  }
}

sub save {
  my ($self) = @_;
  $self = $self->the unless ref($self);
  io->file(JSON_CONFIG) < to_json($self->{config}, { pretty => 1 });
}

1;
