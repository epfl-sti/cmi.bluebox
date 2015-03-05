#!/usr/bin/perl -w

package EPFLSTI::BlueBox::VNCTarget;

use strict;

=head1 NAME

EPFLSTI::BlueBox::VNCTarget - Model for a VNC endpoint.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  perl -MJSON -MEPFLSTI::BlueBox::VPN -MEPFLSTI::BlueBox::VNCTarget \
    -e "print EPFLSTI::BlueBox::VNCTarget->all_json(EPFLSTI::BlueBox::VPN->load("My_VPN"))"

=for My::Tests::Below "synopsis" end

=head1 DIRECTORY LAYOUT

=item /srv/vpn/My_VPN_Name/vncs/1

Top directory.

=item /srv/vpn/My_VPN_Name/vncs/1/config.json

View-side data for this VPN. The view can either enumerate the
subdirectories of /srv/vpn/*/vncs that have a config.json file in
them, or use one of the the L</all> or
L<EPFLSTI::Model::PersistentBase/all_json> class methods in a
one-liner.

=cut

use base "EPFLSTI::Model::PersistentBase";

sub _class_moniker { "vncs" }

use Carp;

use List::Util qw(max);

use IO::All;

use Errno qw(EEXIST);

our $_last_attributed_id = 0;
sub _new {
  my ($class, $id) = @_;
  if (! defined $id) {
    $_last_attributed_id = $id =
      1 + (max($_last_attributed_id, map {$_->id} $class->all));
  }

  return bless {
    id => $id,
  }, $class;
}

sub _key { shift->{id} }

sub _new_from_json {
  my ($class, $json) = @_;
  return $class->_new(delete $json->{id});
}

sub all {
  my ($class, $vpn_obj) = @_;
  my @really_all = $class->SUPER::all();
  if (! defined $vpn_obj) {
    return @really_all;
  } else {
    return map {
      ($vpn_obj->get_name() eq $_->{vpn}) ? ($_) : ()
    } @really_all;
  }
}

# Denormalized for the view's comfort:
__PACKAGE__->readonly_persistent_attribute('id');
__PACKAGE__->persistent_attribute($_) for qw(name desc ip port);
__PACKAGE__->foreign_key(vpn => "EPFLSTI::BlueBox::VPN");

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
  $EPFLSTI::BlueBox::VNCTarget::_last_attributed_id = 0;
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
    my $vnc1 = EPFLSTI::BlueBox::VNCTarget->new;
    $vnc1->{vpn} = $vpn->{name};
    $vnc1->{name} = "VNC 1";
    $vnc1->{desc} = "Hello.";
    my $vnc2 = EPFLSTI::BlueBox::VNCTarget->new;
    $vnc2->{vpn} = $vpn->{name};
    $vnc2->{name} = "VNC 2";
  };

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @results = sort { $a->{id} cmp $b->{id} } @$results;

  is_deeply(\@results, [{id => 1, name => "VNC 1", desc => "Hello.",
                         vpn => "My_VPN"},
                        {id => 2, name => "VNC 2", vpn => "My_VPN"}]);
};

test "all_json" => sub {
  reset_tests;
  transaction {
    my $vpn = EPFLSTI::BlueBox::VPN->new("My_VPN");
    my $vnc1 = EPFLSTI::BlueBox::VNCTarget->new;
    $vnc1->{vpn} = $vpn->{name};
    $vnc1->{name} = "VNC 1";
    $vnc1->{desc} = "Hello.";
    my $vnc2 = EPFLSTI::BlueBox::VNCTarget->new;
    $vnc2->{vpn} = $vpn->{name};
    $vnc2->{name} = "VNC 2";
  };
  my @results = sort { $a->{id} cmp $b->{id} }
    @{JSON::decode_json(EPFLSTI::BlueBox::VNCTarget->all_json)};

  is_deeply(\@results, [{id => 1, name => "VNC 1", desc => "Hello.",
                         vpn => "My_VPN"},
                        {id => 2, name => "VNC 2", vpn => "My_VPN"}]);
};
