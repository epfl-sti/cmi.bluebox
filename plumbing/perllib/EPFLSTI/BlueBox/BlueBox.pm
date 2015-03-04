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
L<EPFLSTI::Model::JSONConfigBase/all_json> class methods in a
one-liner.

=cut

use base "EPFLSTI::Model::JSONConfigBase";

use Carp;

use IO::All;

# Blue Box names need to be valid DNS names.
our $NAME_RE = qr/^[a-z0-9.-]+$/;

sub _new {
  my ($class, $vpn_obj, $name) = @_;
  $name = lc($name);
  croak "Bad Blue Box name: $name" unless $name =~ $NAME_RE;
  bless {
    name => $name,
    vpn => $vpn_obj,
    status => "INIT",
  }, $class;
}

sub _new_from_json {
  my ($class, $json) = @_;
  require EPFLSTI::BlueBox::VPN;
  my $vpn_obj = EPFLSTI::BlueBox::VPN->new(delete $json->{vpn});
  return $class->_new($vpn_obj, delete $json->{name});
}

sub all {
  my ($class, $vpn_obj) = @_;
  return $class->_load_from_subdirs($class->_bbox_dir($vpn_obj), $vpn_obj);
}

sub _bbox_dir {
  my (undef, $vpn_obj) = @_;
  return io->dir($vpn_obj->data_dir)->catdir("bboxes")
}

sub data_dir {
  my $self = shift;
  return $self->_bbox_dir($self->{vpn})->catdir($self->{name});
}

# Denormalized for the view's comfort:
__PACKAGE__->readonly_persistent_attribute('name');
__PACKAGE__->persistent_attribute($_) for (qw(desc ip status));

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

use EPFLSTI::BlueBox::VPN;

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

  my $vpn = EPFLSTI::BlueBox::VPN->new("My_VPN");
  my $bbox1 = EPFLSTI::BlueBox::BlueBox->new($vpn, "bbox1");
  $bbox1->{desc} = "Hello.";
  $bbox1->save();
  my $bbox2 = EPFLSTI::BlueBox::BlueBox->new($vpn, "BBOX2.epfl.ch");

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @results = sort { $a->{name} cmp $b->{name} } @$results;

  is_deeply(\@results, [{name => "bbox1", desc => "Hello.",
                         status => "INIT"},
                        {name => "bbox2.epfl.ch", status => "INIT"}]);
};

