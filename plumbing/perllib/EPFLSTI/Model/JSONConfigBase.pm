#!/usr/bin/perl -w

package EPFLSTI::Model::JSONConfigBase;

use strict;

use JSON;

use IO::All;

use Try::Tiny;

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

=head2 _load_from_dirs ($path, @load_args)

Load a series of objects from directories.

Call L</load> in sequence, discarding exceptions.

=cut

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

=head1 METHODS

=head2 save

Save the state to this object's L</json_file>.

=cut

sub save {
  my ($self) = @_;
  $self->_data_dir->mkpath();
  $self->json_file < to_json( $self->TO_JSON, { pretty => 1 } );
}

=head2 json_file

Get the path to the JSON file that contains the state.

=cut

sub json_file { shift->_data_dir->catfile("config.json") }

=head1 ABSTRACT CLASS METHODS

To be defined by the subclasss.

=head2 load (@load_args, $subdirectory_name)

Construct an instance of the class, or raise
L<EPFLSTI::Model::LoadError> if not possible. The last argument
$subdirectory_name will be the name of the subdirectory to load from.

=cut

=head1 ABSTRACT METHODS

To be defined by the subclasss.

=head2 _data_dir ()

Get the directory this object lives in.

=cut


1;

