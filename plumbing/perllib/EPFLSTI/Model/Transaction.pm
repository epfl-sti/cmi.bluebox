#!/usr/bin/perl -w

package EPFLSTI::Model::Transaction;

use strict;

=head1 NAME

EPFLSTI::Model::Transaction - Global transaction entry point

=head1 SYNOPSIS

  use EPFLSTI::Model::Transaction qw(transaction);

  transaction {
    # ...
  };

or

  use EPFLSTI::Model::Transaction;
  EPFLSTI::Model::Transaction->begin;
  # ...
  EPFLSTI::Model::Transaction->commit;

=head1 DESCRIPTION

This is just a convenience proxy for
L<EPFLSTI::Model::PersistentBase/begin_transaction> and
L<EPFLSTI::Model::PersistentBase/commit_transaction>.

=cut

use base 'Exporter';

our @EXPORT_OK = qw(transaction);

use EPFLSTI::Model::PersistentBase;

=head2 begin

Declare intent to perform writes. B<This must be called before
creating any persistent objects,> lest L</commit> refuse to work (this
is for locking reasons).

=cut

sub begin { EPFLSTI::Model::PersistentBase->begin_transaction }

=head2 commit

Commit all changes. All objects created with L</new>
since L</begin_transaction> get their L</on_commit> method called, and
then their new state is written to the flat JSON file.

=cut

sub commit { EPFLSTI::Model::PersistentBase->commit_transaction }

=head2 transaction

Wrap L</begin> and L</commit> in a single syntactic form.

=cut

sub transaction (&) {
  my $code = shift;
  begin;
  $code->();
  commit;
}

__END__
