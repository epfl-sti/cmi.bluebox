#!/usr/bin/perl -w

package EPFLSTI::Model::ReferenceError;

use strict;

use warnings;

require v5.10.0;  # Any version that supports die'ing with a ref, in fact

=head1 NAME

EPFLSTI::Model::ReferenceError - Raised upon referential integrity problems.

=cut

sub new {
  my $class = shift;
  return bless {@_}, $class;
}

sub throw {
  my $class = shift;
  die $class->new(@_);
}

1;
