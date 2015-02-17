#!/usr/bin/perl -w

package EPFLSTI::BlueBox::VPN;

use strict;

=head1 NAME

EPFLSTI::BlueBox::VPN - Model for a Blue Box VPN.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  perl -MJSON -MEPFLSTI::BlueBox::VPN \
    -e "print EPFLSTI::BlueBox::VPN->all_json"

=for My::Tests::Below "synopsis" end

=head1 DIRECTORY LAYOUT

=item /srv/vpn/My_VPN_Name

Top directory.

=item /srv/vpn/My_VPN_Name/config.json

View-side data for this VPN. The view can either enumerate the
subdirectories of /srv/vpn that have a config.json file in them, or
use one of the the L</all> or
L<EPFLSTI::Model::JSONConfigBase/all_json> class methods in a
one-liner.

=cut

use base "EPFLSTI::Model::JSONConfigBase";

use EPFLSTI::Model::LoadError;

use IO::All;

# Constrained by OpwenWRT code; see also VPN.validName in the JS code.
our $NAME_RE = qr/^[A-Za-z0-9_]+$/;

use EPFLSTI::Docker::Paths;

BEGIN {
  *DATA_DIR = EPFLSTI::Docker::Paths->settable_srv_subpath("vpn");
  *TINC_DIR = EPFLSTI::Docker::Paths->settable_srv_subpath("etc/tinc");
}

sub _new {
  my ($class, $vpn_name) = @_;
  die "Bad VPN name: $vpn_name" unless $vpn_name =~ $NAME_RE;
  bless {
    name => $vpn_name,
  }, $class;
}

sub new {
  my $self = _new(@_);
  return $self if $self->json_file->exists;
  $self->save();
  return $self;
}

sub load {
  my ($class, $vpn_name) = @_;
  my $self = _new(@_);
  throw EPFLSTI::Model::LoadError(
    message => "Not a VPN directory",
    dir => $self->_data_dir) unless ($self->json_file->exists);
  return $self;
}

sub all {
  my ($class) = @_;
  return $class->_load_from_subdirs(DATA_DIR);
}

sub TO_JSON {
  my ($self) = @_;
  return { name => $self->{name} };
}

sub _data_dir { io->catdir(DATA_DIR, shift->{name}) }

1;

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/BlueBox/VPN.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use Set::Scalar;

use JSON;

use IO::All;

use EPFLSTI::Docker::Paths;

EPFLSTI::Docker::Paths->srv_dir(My::Tests::Below->tempdir);

test "synopsis" => sub {
  my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");

  my $perlformula = join(" ", $^X, map { "-I" . io($_)->absolute } @INC);

  $synopsis =~ s/\bperl\b/$perlformula/;  # Not /g

  my $tempdir = My::Tests::Below->tempdir;
  my $begin_for_tests = <<"BEGIN_FOR_TESTS";
use EPFLSTI::Docker::Paths;
EPFLSTI::Docker::Paths->srv_dir("$tempdir");
BEGIN_FOR_TESTS

  $synopsis =~ s/-e/-e 'BEGIN { $begin_for_tests }' -e/;  # Still no /g

  # While we're here, cover the creation code paths:

  EPFLSTI::BlueBox::VPN->new("My_First_VPN");
  EPFLSTI::BlueBox::VPN->new("My_Second_VPN");

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @vpn_names = map {$_->{name}} @$results;
  ok(Set::Scalar->new(@vpn_names)->is_equal(
    Set::Scalar->new(qw(My_First_VPN My_Second_VPN))));
};

test "all_json" => sub {
  # Basically same as above, sans snarfing the code from the POD.
  EPFLSTI::BlueBox::VPN->new("My_First_VPN");
  EPFLSTI::BlueBox::VPN->new("My_Second_VPN");
  # Red herring:
  io->dir(My::Tests::Below->tempdir)->dir("vpn")->dir("No_Third_VPN")
    ->mkpath->file("config.bson") < '{"name" : "Red herring", }';

  ok ((my $results = JSON::decode_json(EPFLSTI::BlueBox::VPN->all_json())),
      "Tastes like JSON");

  my $expected = Set::Scalar->new(qw(My_First_VPN My_Second_VPN));
  my $got = Set::Scalar->new(map {$_->{name}} @$results);
  ok($expected->is_equal($got))
    or diag "Unexpected: " . ($got - $expected) .
    ", missing: " . ($expected - $got);
};

test "Cannot create VPN with wrong name" => sub {
  is eval {
    EPFLSTI::BlueBox::VPN->new("No.such.VPN");
    1;
  }, undef;
};

