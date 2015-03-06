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

use Try::Tiny;

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

=head2 rollback

Discard all changes. Can be called regardless of whether L</begin> was
called first.

=cut

sub rollback { EPFLSTI::Model::PersistentBase->rollback_transaction }

=head2 transaction

Wrap L</begin> and L</commit> in a single syntactic form.

=cut

sub transaction (&) {
  my $code = shift;
  begin;
  try {
    $code->();
    commit;
  } catch {
    my $exn = $_;
    rollback;
    die $exn;
  }
}

1;

require My::Tests::Below unless caller();

__END__

use Test::More qw(no_plan);
use Test::Group;
use Try::Tiny;

use EPFLSTI::Model::Transaction qw(transaction);

our $counts;

sub reset_tests {
  $counts = { begun => 0, committed => 0, rolled_back => 0};  # Ah, ah, ah !
};

{
  no warnings "redefine";
  sub EPFLSTI::Model::PersistentBase::begin_transaction {
    $counts->{begun}++;
  }

  sub EPFLSTI::Model::PersistentBase::commit_transaction {
    $counts->{committed}++;
  }

  sub EPFLSTI::Model::PersistentBase::rollback_transaction {
    $counts->{rolled_back}++;
  }
}

test "throwing in transaction" => sub {
  reset_tests;
  try {
    transaction {
      die "FAIL";
      fail("Should not go here");
    };
    fail("Should not go here either");
  } catch {
    like($_, qr/^FAIL/);
  };
  is($counts->{begun}, 1);
  is($counts->{committed}, 0);
  is($counts->{rolled_back}, 1);

  # We must be able to start a new transaction right away:
  transaction { pass };
  is($counts->{begun}, 2);
  is($counts->{committed}, 1);
  is($counts->{rolled_back}, 1);
};
