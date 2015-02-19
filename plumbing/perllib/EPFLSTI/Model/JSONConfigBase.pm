#!/usr/bin/perl -w

package EPFLSTI::Model::JSONConfigBase;

use strict;

=head1 NAME

EPFLSTI::Model::JSONConfigBase - Base class for JSON-described model classes

=head1 DESCRIPTION

Instances of a typical model class in EPFLSTI-ware have all their
persistent state saved to a JSON file, where the view (typically not
in Perl) can inspect it. If the class is not a singleton, the various
instances have each their own config.json file organized like this:

    /srv/myclass
           |
           +-- MyFirstInstance
           |     |
           |     +-- config.json
           |
           +-- MySecondInstance
                 |
                 +-- config.json

where the subdirectory name is the primary key to the object's identity.

This base class makes it easy to churn out classes that work like that.

=head1 CLASS METHODS

=head2 _load_from_subdirs ($path, @load_args)

Load a series of objects from directories.

Call L</load> in sequence, discarding exceptions. @load_args is the
list of arguments to pass to L</load>, minus the last one which is
assumed to be the name of the subdirectory to load from.

=cut

use JSON;

use IO::All;

use Try::Tiny;

sub _load_from_subdirs {
  my ($class, $path, @load_args) = @_;
  return map {
    try {
      $class->load(@load_args, $_->filename);
    } catch {
      unless (UNIVERSAL::isa($_, "EPFLSTI::Model::LoadError")) {
        die $_;
      }
      ()
    }
  } (io->dir($path)->all_dirs);
}

=head2 all_json (@args_for_all)

Returns all instances of the class obtained with C<<
$class->all(@args_for_all) >>, as a single string in JSON form.

=cut

sub all_json {
  my $class = shift;
  return to_json([$class->all(@_)], { pretty => 1, convert_blessed => 1 });
}

=head2 mk_accessors (@names)

L<Class::Accessor> style, with best practices, sans all the crud.

=cut

sub mk_accessors {
  my $pkg = shift;
  foreach my $field_name (@_) {
    my $get = sub { shift->{$field_name} };
    my $set = sub {
      my $self = shift;
      $self->{$field_name} = shift;
    };
    no strict "refs";
    *{"${pkg}::get_${field_name}"} = $get;
    *{"${pkg}::set_${field_name}"} = $set;
  }
}

=head1 METHODS

=head2 load ()                    # Instance method

=head2 load (@constructor_args)   # Class method

Load the object from the directory indicated by $subdirectory_name.

If not possible, raise L<EPFLSTI::Model::LoadError>.

=cut

sub load {
  my $self_or_class = shift;
  my $self = ref($self_or_class) ? $self_or_class:
    $self_or_class->_new(@_);
  throw EPFLSTI::Model::LoadError(
    message => "Not a VPN directory",
    dir => $self->data_dir) unless ($self->json_file->exists);
  my %data = %{from_json($self->json_file->slurp)};
  while(my ($key, $value) = each %data) {
    $self->{$key} = $value;
    # Allow smart overloads of L</save>:
    $self->{"${key}_ORIG"} = $value;
  }
  return $self;
}

=head2 new (@constructor_args)

L</load> or create this object.

=cut

sub new {
  my $class = shift;
  my $self = $class->_new(@_);
  if ($self->json_file->exists) {
    $self->load();
  } else {
    $self->save();
  }
  return $self;
}


=head2 save

Save the state to this object's L</json_file>.

=cut

sub save {
  my ($self) = @_;
  $self->data_dir->mkpath();
  $self->json_file < to_json( $self->TO_JSON, { pretty => 1 } );
}

=head2 json_file

Get the path to the JSON file that contains the state.

=cut

sub json_file { shift->data_dir->catfile("config.json") }

=head1 ABSTRACT CLASS METHODS

To be defined by the subclasss.

=head2 _new (@constructor_args)

Construct an instance of the class. The arguments are supposed to
select an instance only, so that @constructor_args can be passed as-is
from L</new> or L</load>; mutations should be done by caller in
another statement.

=cut

=head1 ABSTRACT METHODS

To be defined by the subclasss.

=head2 data_dir ()

Get the directory this object lives in, as an L<IO::All> directory
handle.

=head2 TO_JSON ()

Return the subset of $self->{} attributes that are persistent, in an
unblessed hash reference. L</load> will put them right back.

=cut

1;

require My::Tests::Below unless caller();

1;

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Model/JSONConfigBase.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use JSON;

use IO::All;

our $testdir = io->dir(My::Tests::Below->tempdir)->dir("myobj");

{
  package My::JSONClass;
  use base 'EPFLSTI::Model::JSONConfigBase';

  use IO::All;

  sub _new { bless {}, shift }

  # Note: because data_dir is so simple, this class is in fact a singleton.
  sub data_dir { $testdir }

  sub TO_JSON {
    my $self = shift;
    return { foo => $self->{foo}, bar => $self->{bar} };
  }

  My::JSONClass->mk_accessors(qw(zoinx));
}

test "->new(), ->save() and ->load()" => sub {
  $testdir->rmtree;

  my $obj = new My::JSONClass;
  $obj->{foo} = "Foo";
  $obj->{unsaved} = "Baz";
  $obj->save();
  $obj = load My::JSONClass;
  is $obj->{foo}, "Foo";
  ok(! exists $obj->{unsaved});
  is($obj->{bar}, undef);
};

test "->new() on existing object" => sub {
  $testdir->rmtree;

  my $obj = new My::JSONClass;
  $obj->{foo} = "Foo";
  $obj->save();

  $obj = new My::JSONClass;
  is $obj->{foo}, "Foo";
};

test "ORIG_foo and load" => sub {
  $testdir->rmtree;

  my $obj = new My::JSONClass;
  $obj->{foo} = "Foo";
  is $obj->{foo_ORIG}, undef;
  $obj->save();

  $obj = load My::JSONClass;
  $obj->{foo} = "Bar";
  is $obj->{foo}, "Bar";
  is $obj->{foo_ORIG}, "Foo";
};

test "Accessors" => sub {
  $testdir->rmtree;

  my $obj = new My::JSONClass;
  $obj->{zoinx} = "Zoinx";
  is($obj->get_zoinx, "Zoinx");

  $testdir->rmtree;

  $obj = new My::JSONClass;
  $obj->set_zoinx("Mew");
  is($obj->{zoinx}, "Mew");
};
