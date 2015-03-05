#!/usr/bin/perl -w

package EPFLSTI::BlueBox::BlueBox;

use strict;

=head1 NAME

EPFLSTI::BlueBox::BlueBox - Model for a Blue Box.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  perl -MJSON -MEPFLSTI::BlueBox::VPN -MEPFLSTI::BlueBox::BlueBox \
    -e "print EPFLSTI::BlueBox::BlueBox->all_json(EPFLSTI::BlueBox::VPN->load("My_VPN"))"

=for My::Tests::Below "synopsis" end

=head1 DIRECTORY LAYOUT

=item /srv/vpn/My_VPN_Name/bboxes/My_BlueBox_Name

Top directory.

=item /srv/vpn/My_VPN_Name/bboxes/My_BlueBox_Name/config.json

View-side data for this VPN. The view can either enumerate the
subdirectories of /srv/vpn/*/bboxes that have a config.json file in
them, or use one of the the L</all> or
L<EPFLSTI::Model::PersistentBase/all_json> class methods in a
one-liner.

=cut

use base "EPFLSTI::Model::PersistentBase";

sub _class_moniker { "bboxes" }

use Carp;

# Blue Box names need to be valid DNS names.
our $NAME_RE = qr/^[a-z0-9.-]+$/;

sub _new {
  my ($class, $name) = @_;
  $name = lc($name);
  croak "Bad Blue Box name: $name" unless $name =~ $NAME_RE;
  bless {
    name => $name,
    status => "INIT",
  }, $class;
}

sub _new_from_json {
  my ($class, $json) = @_;
  return $class->_new(delete $json->{name});
}

sub all {
  my ($class, $vpn_obj) = @_;
  my @really_all = $class->SUPER::all();
  if (! defined $vpn_obj) {
    return @really_all;
  } else {
    return map {
      ($vpn_obj->get_name() eq $_->get_vpn) ? ($_) : ()
    } @really_all;
  }
}

# Denormalized for the view's comfort:
__PACKAGE__->readonly_persistent_attribute('name');
__PACKAGE__->persistent_attribute($_) for (qw(desc ip status));
__PACKAGE__->foreign_key("vpn", "EPFLSTI::BlueBox::VPN");

require My::Tests::Below unless caller();

1;

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/BlueBox/VPN.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use JSON;

use IO::All;

use EPFLSTI::Docker::Paths;

use EPFLSTI::Model::Transaction qw(transaction);
use EPFLSTI::BlueBox::VPN;

EPFLSTI::Docker::Paths->srv_dir(My::Tests::Below->tempdir);

sub reset_tests {
  transaction (sub {});
  io(EPFLSTI::Model::PersistentBase->FILE)->unlink;
}

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

  transaction {
    my $vpn = EPFLSTI::BlueBox::VPN->new("My_VPN");
    my $bbox1 = EPFLSTI::BlueBox::BlueBox->new("bbox1");
    $bbox1->{vpn} = $vpn->{name};
    $bbox1->{desc} = "Hello.";
    my $bbox2 = EPFLSTI::BlueBox::BlueBox->new("BBOX2.epfl.ch");
    $bbox2->{vpn} = $vpn->{name};
  };

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @results = sort { $a->{name} cmp $b->{name} } @$results;

  is_deeply(\@results, [{name => "bbox1", desc => "Hello.",
                         status => "INIT", vpn => "My_VPN"},
                        {name => "bbox2.epfl.ch", status => "INIT",
                         vpn => "My_VPN"}]);
};

test "all_json" => sub {
  reset_tests;
  transaction {
    my $vpn = EPFLSTI::BlueBox::VPN->new("My_VPN");
    my $bbox1 = EPFLSTI::BlueBox::BlueBox->new("bbox1");
    $bbox1->{vpn} = $vpn->{name};
    $bbox1->{desc} = "Hello.";
    my $bbox2 = EPFLSTI::BlueBox::BlueBox->new("BBOX2.epfl.ch");
    $bbox2->{vpn} = $vpn->{name};
  };
  my @results = sort { $a->{name} cmp $b->{name} }
    @{JSON::decode_json(EPFLSTI::BlueBox::BlueBox->all_json)};

  is_deeply(\@results, [{name => "bbox1", desc => "Hello.",
                         status => "INIT", vpn => "My_VPN"},
                        {name => "bbox2.epfl.ch", status => "INIT",
                         vpn => "My_VPN"}]);

};
