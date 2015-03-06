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

=cut

use base qw(EPFLSTI::Model::PersistentBase);

use IO::All;

# Constrained by OpwenWRT code; see also VPN.validName in the JS code.
our $NAME_RE = qr/^[A-Za-z0-9_]+$/;

use EPFLSTI::Docker::Paths;

sub _new {
  my ($class, $keyref) = @_;
  die "Need name as primary key" unless defined(
    my $vpn_name = $keyref->[0]);
  die "Bad VPN name: $vpn_name" unless $vpn_name =~ $NAME_RE;
  bless {
    name => $vpn_name,
  }, $class;
}

sub _key_from_json {
  my ($class, $json) = @_;
  return delete $json->{name};
}

# Denormalized for the view's comfort:
__PACKAGE__->readonly_persistent_attribute('name');
__PACKAGE__->persistent_attribute('desc');

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
use EPFLSTI::Model::JSONStore;
use EPFLSTI::Model::Transaction qw(transaction);

EPFLSTI::Docker::Paths->srv_dir(My::Tests::Below->tempdir);

my $tempdir = io(My::Tests::Below->tempdir);

sub reset_tests {
  transaction (sub {});
  io(EPFLSTI::Model::JSONStore->FILE)->unlink;
}

test "synopsis" => sub {
  reset_tests;
  my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");

  my $perlformula = join(" ", $^X, map { "-I" . io($_)->absolute } @INC);

  $synopsis =~ s/\bperl\b/$perlformula/;  # Not /g

  my $begin_for_tests = <<"BEGIN_FOR_TESTS";
use EPFLSTI::Docker::Paths;
EPFLSTI::Docker::Paths->srv_dir("$tempdir");
BEGIN_FOR_TESTS

  $synopsis =~ s/-e/-e 'BEGIN { $begin_for_tests }' -e/;  # Still no /g

  # While we're here, cover the creation code paths:

  transaction {
    EPFLSTI::BlueBox::VPN->new("My_First_VPN");
    EPFLSTI::BlueBox::VPN->new("My_Second_VPN");
  };

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @vpn_names = map {$_->{name}} @$results;
  ok(Set::Scalar->new(@vpn_names)->is_equal(
    Set::Scalar->new(qw(My_First_VPN My_Second_VPN))));
};

test "all_json" => sub {
  # Basically same as above, sans snarfing the code from the POD.
  reset_tests;
  transaction {
    EPFLSTI::BlueBox::VPN->new("My_First_VPN");
    EPFLSTI::BlueBox::VPN->new("My_Second_VPN");
  };

  ok ((my $results = JSON::decode_json(EPFLSTI::BlueBox::VPN->all_json())),
      "Tastes like JSON");

  my $expected = Set::Scalar->new(qw(My_First_VPN My_Second_VPN));
  my $got = Set::Scalar->new(map {$_->{name}} @$results);
  ok($expected->is_equal($got))
    or diag "Unexpected: " . ($got - $expected) .
    ", missing: " . ($expected - $got);
};

test "Accessors" => sub {
  reset_tests;
  transaction {
    my $vpn = EPFLSTI::BlueBox::VPN->new("My_First_VPN");
    $vpn->set_desc("This is my first VPN.");
  };
  is(EPFLSTI::BlueBox::VPN->load("My_First_VPN")->get_desc,
    "This is my first VPN.");
};

test "Cannot create VPN with wrong name" => sub {
  is eval {
    EPFLSTI::BlueBox::VPN->new("No.such.VPN");
    1;
  }, undef;
};

