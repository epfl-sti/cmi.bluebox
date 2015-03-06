#!/usr/bin/perl -w

package EPFLSTI::Model::PersistentBase;

use strict;

=head1 NAME

EPFLSTI::Model::PersistentBase - Base class for JSON-described model classes

=head1 DESCRIPTION

Applications in typical EPFLSTI-ware have all their persistent state
saved to a flat JSON file, where the view (typically not in Perl) can
inspect it. This base class makes it easy to churn out classes that
work like that.

=head1 CLASS METHODS

=cut

use IO::All;
use JSON;
use Try::Tiny;

use EPFLSTI::Model::ReferenceError;
use EPFLSTI::Model::JSONStore;
use EPFLSTI::Docker::Paths;

=head2 FILE

Get (or set, in tests) the path to the flat JSON file containing
everything.

=cut

BEGIN {
  *FILE = EPFLSTI::Docker::Paths->settable_srv_subpath("fleet_state.json");
}

my $transaction = {};

sub _store {
  return ($transaction->{store} ||= EPFLSTI::Model::JSONStore->open(FILE));
}

sub _mark_for_deletion {
  my ($self) = @_;
  # Silently ignore attempts to delete objects created outside of the
  # transaction
  if (exists $transaction->{objects}->{$self->_uniqueness_token}) {
    push @{$transaction->{will_be_deleted}}, shift;
  }
}

=head2 load (@key)                # Class method

Load the object from the flat JSON file.

If not possible, raise L<EPFLSTI::Model::ReferenceError>.

=head2 create (@key)

Assert that this object doesn't already exist.

Otherwise, raise L<EPFLSTI::Model::ReferenceError>.

=cut

sub load {
  my $self = _get_unique_instance(@_);
  defined(my $deflated = _get_from_store(_store, $self)) or
      throw EPFLSTI::Model::ReferenceError(
        message => "Object does not exist",
        key => [@_]);
  return $self->_inflate($deflated);
}

sub create {
  my $self = _get_unique_instance(@_);
  defined(_get_from_store(_store, $self)) &&
    throw EPFLSTI::Model::ReferenceError(
      message => "Object already exists",
      key => [@_]);
  return $self;
}

=head2 new (@key)

L</load> or L</create> this object.

=cut

sub new {
  my $self = _get_unique_instance(@_);
  my $deflated = _get_from_store(_store, $self);
  if ($deflated) {
    $self->_inflate($deflated);
  }
  return $self;
}

sub _get_unique_instance {
  my ($class, @key) = @_;
  my $self = $class->_new(@key);
  $self->{_PersistentBase__key} = [@key];
  return ($transaction->{objects}->{$self->_uniqueness_token} ||= $self);
}

sub _get_from_store {
  my ($store, $self) = @_;
  return $store->get($self->_class_moniker, $self->_key_as_string);
}

sub _inflate {
  my ($self, $deflated) = @_;
  while(my ($key, $value) = each %$deflated) {
    $self->{$key} = $value;
    # Allow overloaded L</on_commit> methods to act smart:
    $self->{"${key}_ORIG"} = $value;
  }
  return $self;
}

=head2 all

Return all previously persisted instances of the class.

=cut

sub all {
  my ($class) = @_;
  return map { $class->load($_) }
    (keys %{_store->get_all($class->_class_moniker)});
}

=head2 all_json (@args_for_all)

Returns all instances of the class obtained with C<<
$class->all(@args_for_all) >>, as a single string in JSON form.

=cut

sub all_json {
  my $class = shift;
  return to_json([$class->all(@_)], { pretty => 1, convert_blessed => 1 });
}

=head2 begin_transaction

Declare intent to perform writes. B<This must be called before
creating any instance of any subclass,> lest L</commit> refuse to work
(for locking reasons).

=cut

sub begin_transaction {
  my ($class) = @_;
  die "Already in a transaction" if _store->locked;
  _store->lock;
  # Only objects created *during* the transaction will commit.
  $transaction->{objects} = {};
  # Ditto for deletions.
  $transaction->{will_be_deleted} = [];
}

=head2 commit_transaction

Commit all changes. All objects L</load>ed or created with L</new>
since L</begin_transaction> get their L</on_commit> method called, and
then their new state is written to the flat JSON file.

=cut

sub commit_transaction {
  my ($class) = @_;
  die "begin_transaction was not called" unless _store->locked;

  foreach my $object (values %{$transaction->{objects}}) {
      $object->on_commit();
  }
  foreach my $object (values %{$transaction->{objects}}) {
    _store->put($object->_class_moniker, $object->_key_as_string, $object);
  }
  foreach my $object (@{$transaction->{will_be_deleted}}) {
      _store->delete($object->_class_moniker, $object->_key_as_string);
  }
  _store->save;

  $transaction = {};  # WOOSH! File lock, object cache... All gone.
}

=head2 readonly_persistent_attribute ($attr)

Declare the C<< ->{$attr} >> of instances of this class to be
read-only persistent. This has the following effects:

=item *

A L<Class::Accessor>-style get_foo accessor is generated

=item *

L</TO_JSON> will serialize this field

=back

=cut

sub readonly_persistent_attribute {
  my ($pkg, $attr) = @_;
  my $get = sub { shift->{$attr} };
  no strict "refs";
  *{"${pkg}::get_${attr}"} = $get;
  no warnings "once";
  push @{"${pkg}::PERSISTENT_FIELDS"}, $attr;
}

=head2 persistent_attribute ($attr)

Declare the C<< ->{$attr} >> of instances of this class to be
persistent. This has the following effects:

=over 4

=item *

L<Class::Accessor>-style set_foo and get_foo accessors are generated

=item *

L</TO_JSON> and L</update> will serialize resp. update these fields

=back

=cut

sub persistent_attribute {
  my ($pkg, $attr) = @_;
  $pkg->readonly_persistent_attribute($attr);
  my $set = sub {
    my $self = shift;
    $self->{$attr} = shift;
  };
  no strict "refs";
  *{"${pkg}::set_${attr}"} = $set;
  no warnings "once";
  push @{"${pkg}::UPDATEABLE_FIELDS"}, $attr;
}

=head2 foreign_key ($key, $target_perl_package)

Declare the C<< ->{$attr} >> of instances of this class to be a foreign
key into class $target_perl_package.

=cut

sub foreign_key {
  my ($pkg, $attr, $target_class) = @_;
  no warnings "once";

  my $get = sub {
    my ($self) = @_;
    return $target_class->load($self->{$attr});
  };

  my $set = sub {
    my ($self, $newval) = @_;
    if (UNIVERSAL::isa($newval, $target_class)) {
      $newval = $newval->_key;
    };
    $self->{$attr} = $newval;
  };

  no strict "refs";
  *{"${pkg}::get_${attr}"} = $get;
  *{"${pkg}::set_${attr}"} = $set;
  push @{"${pkg}::PERSISTENT_FIELDS"}, $attr;
  push @{"${pkg}::UPDATEABLE_FIELDS"}, $attr;

}

=head2 put_from_stdin

=head2 post_from_stdin

=head2 delete_from_stdin

Read a JSON-encoded data structure from stdin; pass it to
L</json_put>, L</json_post> and L</json_delete>
respectively. Exit with 0 upon success, 4 upon orderly failure.

=cut

sub dump_if_debug {
  return unless ($ENV{DEBUG} && $ENV{DEBUG} =~ m/perl/);
  my ($name, $struct) = @_;
  require Data::Dumper;
  warn Data::Dumper->Dump([$struct], [$name]);
}

foreach my $stem (qw(put post delete)) {
  my $json_marshalling_method = sub {
    my ($class) = @_;
    my $structin = decode_json(io->stdin->slurp);
    dump_if_debug('$structin', $structin);
    try {
      my $structout = $class->can("json_${stem}")->
        ($class, $structin);
      dump_if_debug('$structout', $structout);
      print STDOUT encode_json($structout);
      exit 0;
    } catch {
      die $_ unless ref;
      dump_if_debug('exception', $_);
      print encode_json($_);
      exit 4;
    };
  };
  no strict "refs";
  *{"${stem}_from_stdin"} = $json_marshalling_method;
}

=head2 json_post ($properties_hashref)

=head2 json_put

=head2 json_delete

Implement the Create, Update and Delete API operations respectively,
using the protocol defined by perl.js in the Node.js code.

=cut


sub json_post {
  my ($class, $details) = @_;
  begin_transaction();
  my $self;
  try {
    $self = $class->create($class->_key_from_json($details));
  } catch {
    if (UNIVERSAL::isa($_, "EPFLSTI::Model::ReferenceError")) {
      die({ message => "already exists" });
    } else {
      die $_;
    }
  };
  $self->update($details);
  commit_transaction();
  return $self->TO_JSON();
}

sub json_delete {
  my ($class, $details) = @_;
  begin_transaction();
  $class->load($class->_key_from_json($details))->delete;
  commit_transaction();
  return {
    status => "success"
  };
}

=head1 METHODS

=cut

sub _class_moniker {
  my ($class) = @_;
  my @pkg_parts = split("::", (ref($class) or $class));
  return lc(pop(@pkg_parts)) . "s";
}

sub _key {
  my @key = @{shift->{_PersistentBase__key}};
  return wantarray ? @key : $key[0];
}

sub _key_as_string {
  my ($self) = @_;
  return join("::", $self->_key);
}

sub _uniqueness_token {
  my ($self) = @_;
  return join("::", ref($self), $self->_key_as_string);
}

=head2 delete

Delete the object from the JSON file at transaction commit.

=cut

sub delete {
  _mark_for_deletion(shift);
}

=head2 TO_JSON ()

Return the subset of $self->{} attributes that are
L</persistent_attribute> or L</readonly_persistent_attribute>, in an
unblessed hash reference.

=cut

sub TO_JSON {
  my ($self) = @_;
  my $json = {};
  foreach my $field (do { no strict "refs";
                          @{ref($self) . "::PERSISTENT_FIELDS"} }) {
    $json->{$field} = $self->{$field} if exists $self->{$field};
  }
  return $json;
}

=head2 update ($hashref)

Update all L</persistent_attribute>s from $hashref using the appropriate
setters (i.e., overloading them in a subclass does what you want).

=cut

sub update {
  my ($self, $hashref) = @_;
  foreach my $field (do { no strict "refs";
                          @{ref($self) . "::UPDATEABLE_FIELDS"} }) {
    if (exists $hashref->{$field}) {
      $self->can("set_$field")->($self, $hashref->{$field});
    }
  }
}

=head1 OVERRIDABLE CLASS METHODS

These do nothing in the base class, and may be overridden in
subclasses.

=head2 on_commit

Called at L<EPFLSTI::Model::Transaction/commmit> time.

Subclasses may decide to perform some side effects or enforce
invariants at transaction commit time. If this method throws, the
commit will fail.

=cut

sub on_commit {}

=head1 ABSTRACT CLASS METHODS

To be defined by the subclasss.

=head2 _new (@key)

Construct an instance of the class. The @key arguments should be used
to select an instance only, so that @key can be passed as-is from
L</new> or L</load>. @key is not for setting attributes in new
objects; that should be done by the caller in another statement.

=head2 _new_from_json($jsonstruct)

Like L</_new>, different format of arguments. $jsonstruct is a JSON
structure passed down from Node.js code, that contains the payload of
an HTTP POST, PUT or DELETE request. Like for L<_new>, _new_from_json
should only extract the information that identifies the instance from
$jsonstruct, not use it to set attributes.

=head1 ABSTRACT METHODS

To be defined by the subclasss.

=head2 data_dir ()

Get the directory this object lives in, as an L<IO::All> directory
handle.

=cut

1;

require My::Tests::Below unless caller();

1;

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Model/PersistentBase.pm

__END__

use Scalar::Util qw(refaddr);

use Test::More qw(no_plan);
use Test::Group;
use Try::Tiny;

use JSON;

use IO::All;

use EPFLSTI::Model::Transaction qw(transaction);

our $testjsonfile = io->dir(My::Tests::Below->tempdir)->
  catfile("state.json");
EPFLSTI::Model::PersistentBase->FILE("$testjsonfile");

sub reset_tests {
  transaction (sub {});
  $testjsonfile->unlink;
}

{
  package My::Class;
  use base 'EPFLSTI::Model::PersistentBase';

  sub _new { bless {}, shift }

  My::Class->persistent_attribute($_) for (qw(foo bar zoinx));
}

test "->new() and ->load()" => sub {
  reset_tests;

  transaction {
    my $obj = new My::Class;
    $obj->{foo} = "Foo";
    $obj->{unsaved} = "Baz";
  };

  my $obj = load My::Class;
  is $obj->{foo}, "Foo";
  ok(! exists $obj->{unsaved});
  is($obj->{bar}, undef);
};

test "->new() on existing object" => sub {
  reset_tests;

  transaction {
    my $obj = new My::Class;
    $obj->{foo} = "Foo";
  };

  my $obj = new My::Class;
  is $obj->{foo}, "Foo";
};

test "ORIG_foo and load" => sub {
  reset_tests;

  transaction {
    my $obj = new My::Class;
    $obj->{foo} = "Foo";
    is $obj->{foo_ORIG}, undef;
  };

  my $obj = load My::Class;
  $obj->{foo} = "Bar";
  is $obj->{foo}, "Bar";
  is $obj->{foo_ORIG}, "Foo";
};

test "Uniqueness of objects in memory" => sub {
  reset_tests;

  my $obj1 = new My::Class("key1");
  my $obj1too = new My::Class("key1");
  is(refaddr($obj1), refaddr($obj1too));

  transaction {
    new My::Class("key2");
  };
  my $obj2 = load My::Class("key2");
  my $obj2too = load My::Class("key2");
  is(refaddr($obj2), refaddr($obj2too));
};

test "Mutating objects outside a transaction has no effect" => sub {
  reset_tests;

  transaction {
    My::Class->new->{foo} = 'zoinx';
  };

  do {
    my $obj1 = load My::Class();
    $obj1->{foo} = "bar";
  };

  transaction {
    1;
  };
  my $obj1again = load My::Class();
  is($obj1again->{foo}, 'zoinx');
};

test "Mutating objects loaded outside the transaction has no effect" => sub {
  reset_tests;

  my $obj = new My::Class;
  transaction {
    $obj->{foo} = "Bar";
  };

  try {
    load My::Class;
    fail("Should have thrown");
  } catch {
    is(ref($_), "EPFLSTI::Model::ReferenceError");
  }
};

test "Deleting objects loaded outside the transaction has no effect"
=> sub {
  reset_tests;

  transaction {
    My::Class->new();
  };

  My::Class->load->delete;

  transaction {
    1;
  };

  ok(My::Class->load);
};

test "Accessors" => sub {
  reset_tests;

  my $obj = new My::Class;
  $obj->{zoinx} = "Zoinx";
  is($obj->get_zoinx, "Zoinx");

  reset_tests;

  $obj = new My::Class;
  $obj->set_zoinx("Mew");
  is($obj->{zoinx}, "Mew");
};

My::Class->foreign_key(pointsto => "My::Other::Class");

{
  package My::Other::Class;
  use base 'EPFLSTI::Model::PersistentBase';

  sub _new { bless {}, shift }
}

test "Foreign key getter sets object's key" => sub {
  reset_tests;

  transaction {
    my $obj1 = new My::Class("A");
    $obj1->set_pointsto(new My::Other::Class("target"));
    $DB::single = 1;
    1;
  };
  is(My::Class->load("A")->{pointsto}, "target");
};

test "Foreign key getter returns a ->load()ed object" => sub {
  reset_tests;

  transaction {
    my $obj1 = new My::Class("A");
    $obj1->set_pointsto(new My::Other::Class("target"));
  };
  ok(My::Class->load("A")->get_pointsto->isa("My::Other::Class"));
};

