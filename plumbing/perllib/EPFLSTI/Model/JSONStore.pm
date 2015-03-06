#!/usr/bin/perl -w

package EPFLSTI::Model::JSONStore;

use strict;

=head1 NAME

EPFLSTI::Model::JSONStore - Store tables of objects in a JSON file.

=head1 SYNOPSIS

  use EPFLSTI::Model::JSONStore;

  my $store = EPFLSTI::Model::JSONStore->open("/path/to/file.json");

  my $deflated_json = $store->get("bboxes", "bbox123");
  $store->put("bboxes", "bbox456", $deflated_json);
  $store->delete("bboxes", "bbox789");

  $store->lock();  # Acquire write lock
  $store->save();  # and release lock

=head1 DESCRIPTION

=cut

use Errno;
use Try::Tiny;
use IO::All;
use JSON;

use EPFLSTI::Docker::Paths;

=head2 FILE

Get (or set, in tests) the path to the flat JSON file containing
everything.

=cut

BEGIN {
  *FILE = EPFLSTI::Docker::Paths->settable_srv_subpath("fleet_state.json");
}

=head2 open ($filename)

Open this JSON store for reading (defaults to L</FILE>).

=cut

sub open {
  my ($class, $filename) = @_;
  $filename ||= FILE;

  return bless {
    filename => $filename,
  }, $class;
}

=head2 everything

Cache and return the decoded contents of the file.

=cut

sub everything {
  my ($self) = @_;
  if (! $self->{everything}) {
    local $!;
    try {
      $self->{everything} = decode_json(
        scalar io->file($self->{filename})->slurp);
    } catch {
      if ($! == Errno::ENOENT) { die $_; }
      $self->{everything} = {};
    };
  }
  return $self->{everything};
}

=head2 get ($table, $key)

Return the JSON structure associated with $key in $table.

=head2 get_all ($table)

Iterate L</get> on all objects in this table.

=head2 put ($table, $key, $structure)

Set the JSON structure for $key in $table to $structure.

=head2 delete($table, $key)

Delete the JSON structure for $key in $table.

=cut

sub get {
  my ($self, $table, $key) = @_;
  return $self->everything->{$table}->{$key};
}

sub get_all {
  my ($self, $table, $key) = @_;
  return $self->everything->{$table} || {};
}

sub put {
  my ($self, $table, $key, $structure) = @_;
  if (UNIVERSAL::can($structure, "TO_JSON")) {
    $structure = $structure->TO_JSON();
  }
  $self->everything->{$table}->{$key} = $structure;
}

sub delete {
  my ($self, $table, $key) = @_;
  delete $self->everything->{$table}->{$key};
}

=head2 lock ()

Acquire an exclusive write lock.

Read locks are not needed because L</save> is an atomic replace.

Note that the only way to release the lock is to unref this object.

=cut

sub lock {
  my ($self) = @_;
  $self->{lock} = io->file($self->{filename})->mode(">>")->open->lock;
}

=head2 locked ()

True iff L</lock> was called before.

=cut

sub locked { !(! shift->{lock}) }

=head2 save ()

Save the state to the file as an atomic replace.

This does B<not> check that the object is L</locked>.

=cut

sub save {
  my ($self) = @_;
  my $new_json_file = io->file($self->{filename} . '.new');
  $new_json_file->print(JSON->new->utf8->pretty->encode($self->everything));
  $new_json_file->rename($self->{filename});
}

1;

__END__
