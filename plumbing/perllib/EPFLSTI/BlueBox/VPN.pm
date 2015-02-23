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

use base qw(EPFLSTI::Model::JSONConfigBase);

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

sub all {
  my ($class) = @_;
  return $class->_load_from_subdirs(DATA_DIR);
}

sub TO_JSON {
  my ($self) = @_;
  # The name is denormalized for the view's comfort and also for
  # ->all_json to make sense.
  return { name => $self->{name}, desc => $self->{desc} };
}

sub data_dir { io->catdir(DATA_DIR, shift->{name}) }

=head1 CONTROLLER CLASS METHODS

=head2 post_from_stdin

Read new VPN object in JSON form from standard input; print the JSON
representation of { id => "NewName" } to standard output.

=cut

sub post_from_stdin {
  print STDOUT '{ "id": "Foo" }';
}

sub put_from_stdin {
}

sub delete_from_stdin {
}

__PACKAGE__->mk_accessors(qw(desc));

require My::Tests::Below unless caller();

1;

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

my $tempdir = io(My::Tests::Below->tempdir);

test "synopsis" => sub {
  $tempdir->rmtree;
  my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");

  my $perlformula = join(" ", $^X, map { "-I" . io($_)->absolute } @INC);

  $synopsis =~ s/\bperl\b/$perlformula/;  # Not /g

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
  $tempdir->rmtree;
  EPFLSTI::BlueBox::VPN->new("My_First_VPN");
  EPFLSTI::BlueBox::VPN->new("My_Second_VPN");
  # Red herring:
  io->dir(My::Tests::Below->tempdir)->dir("vpn")->dir("No_Third_VPN")
    ->mkpath->file("config.bson") < '{"name" : "Red herring", }';

  $DB::single = 1;
  ok ((my $results = JSON::decode_json(EPFLSTI::BlueBox::VPN->all_json())),
      "Tastes like JSON");

  my $expected = Set::Scalar->new(qw(My_First_VPN My_Second_VPN));
  my $got = Set::Scalar->new(map {$_->{name}} @$results);
  ok($expected->is_equal($got))
    or diag "Unexpected: " . ($got - $expected) .
    ", missing: " . ($expected - $got);
};

test "Accessors" => sub {
  $tempdir->rmtree;
  my $vpn = EPFLSTI::BlueBox::VPN->new("My_First_VPN");
  $vpn->set_desc("This is my first VPN.");
  $vpn->save();
  is(EPFLSTI::BlueBox::VPN->load("My_First_VPN")->get_desc,
    "This is my first VPN.");
};

test "Cannot create VPN with wrong name" => sub {
  is eval {
    EPFLSTI::BlueBox::VPN->new("No.such.VPN");
    1;
  }, undef;
};

