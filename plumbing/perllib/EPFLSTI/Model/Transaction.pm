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

Handle the transactions over L<EPFLSTI::Model::PersistentBase> instances.

=cut

use base 'Exporter';

our @EXPORT_OK = qw(transaction $persistence);

use Try::Tiny;
use EPFLSTI::Model::JSONStore;

my $transaction;
__PACKAGE__->rollback();  # Populates $transaction

=head1 USER-LEVEL API

=head2 begin

Declare intent to perform writes. B<This must be called before
creating any persistent objects,> lest L</commit> refuse to work (this
is for locking reasons).

=cut

sub begin {
  my ($class) = @_;
  my $self = $transaction;
  die "Already in a transaction" if $self->_store->locked;
  $self->_store->lock;
  # Only objects created *during* the transaction will commit.
  $self->{cache} = {} ;
  # Ditto for deletions.
  $self->{will_be_deleted} = [];
}

=head2 commit

Commit all changes. All objects created with L</new>
since L</begin_transaction> get their L</on_commit> method called, and
then their new state is written to the flat JSON file.

=cut

sub commit {
  my ($class) = @_;
  my $self = $transaction;

  die "begin_transaction was not called" unless $self->_store->locked;

  foreach my $object (values %{$self->{cache}}) {
      $object->on_commit();
  }
  foreach my $object (values %{$self->{cache}}) {
    $self->_store->put($object->class_moniker,
                       join("::", $object->key), $object);
  }
  foreach my $object (@{$self->{will_be_deleted}}) {
      $self->_store->delete($object->class_moniker,
                            join("::", $object->key));
  }
  $self->_store->save;

  $class->rollback();
}

=head2 rollback

Discard all changes. Can be called regardless of whether L</begin> was
called first.

=cut

sub rollback {
  my ($class) = @_;
  $transaction = bless { cache => {} }, $class;
  return;  # Don't leak the singleton object
}

=head2 transaction

Wrap L</begin> and L</commit> in a single syntactic form.

=cut

sub transaction (&) {
  my $code = shift;
  begin;
  try {
    $code->();
    __PACKAGE__->commit;
  } catch {
    my $exn = $_;
    __PACKAGE__->rollback;
    die $exn;
  }
}

sub _store {
  my ($self) = @_;
  return ($self->{store} ||= EPFLSTI::Model::JSONStore->open());
}

=head1 EPFLSTI::Model::Transaction::ObjectLifecycle CLASS

This API is for the private use of L<EPFLSTI::Model::PersistentBase>
only. User code should never call it.

An instance of this class represents all the metadata that the
transaction knows about a given L<> instance. Instances are memoized
by both key and object identity.

=cut

package EPFLSTI::Model::Transaction::ObjectLifecycle;

sub _uniqueness_token {
  my ($self, @keyelems) = @_;
  if (@keyelems == 1 && ref($keyelems[0])) {
    my $obj = $keyelems[0];
    @keyelems = ($obj->class_moniker, $obj->key);
  }
  return join("::", @keyelems);
}

=head2 peek ($class_moniker, @key)

Look whether an object was previously L</put> with this $class_moniker
and @key, and return it.

=cut

sub peek {
  my $class = shift;
  return $transaction->{cache}->{_uniqueness_token(@_)};
}

=head2 put ($object, $class_moniker, @key)

Register a L<EPFLSTI::Model::PersistentBase> instance for mutation.

Putting an object is the only way that it can be saved when the
transaction commits.

=cut

sub put {
  my (undef, $object, $moniker, @key) = @_;
  $transaction->{cache}->{_uniqueness_token($moniker, @key)} = $object;
  $object->{_EPFLSTI_Model_Transaction__key} = [@key];
}

=head2 delete ($object)

Register a L<EPFLSTI::Model::PersistentBase> instance for deletion.

This is the only way that it can be saved when the transaction
commits. L</put> must have been called beforehand, or C<delete> will
have no effect.

=cut

sub delete {
  my (undef, $object) = @_;
  my $k = _uniqueness_token($object);
  if (! exists $transaction->{cache}->{$k}) {
    # Silently ignore attempts to delete objects created outside of the
    # transaction
    return;
  }
  push @{$transaction->{will_be_deleted}}, $object;
  delete $transaction->{cache}->{$k};
}

=head2 get_key ($object)

Return the @key that that object was L</put> under.

=cut

sub get_key {
  my (undef, $object) = @_;
  return @{$object->{_EPFLSTI_Model_Transaction__key}};
}

=head1 EPFLSTI::Model::Transaction::ReadData CLASS

An unencapsulated, read-only facet of the data store.

This is for use by L<EPFLSTI::Model::PersistentBase>. Write access
remains a concern of the transaction for obvious reasons, and is thus
not accessible through this module.

=cut

package EPFLSTI::Model::Transaction::ReadData;

=head2 load_data ($class_moniker, @key)

Read the data for an object out of the data store.

Return undef if that key is not in the database.

=cut

sub load_data {
  my (undef, $class_moniker, @key) = @_;
  return $transaction->_store->get($class_moniker, join("::", @key));
}

=head2 all_keys ($class_moniker)

Read all keys in a given table.

=cut

sub load_all_keys {
  my ($class, $moniker) = @_;
  return keys %{$transaction->_store->get_all($moniker)};
}


package EPFLSTI::Model::Transaction::ReadData;

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
  sub EPFLSTI::Model::Transaction::begin {
    $counts->{begun}++;
  }

  sub EPFLSTI::Model::Transaction::commit {
    $counts->{committed}++;
  }

  sub EPFLSTI::Model::Transaction::rollback {
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
