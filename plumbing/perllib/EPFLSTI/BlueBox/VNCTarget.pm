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
L<EPFLSTI::Model::JSONConfigBase/all_json> class methods in a
one-liner.

=cut

use base "EPFLSTI::Model::JSONConfigBase";

use Carp;

use IO::All;

use Errno qw(EEXIST);

sub _new {
  my ($class, $vpn_obj, $id) = @_;
  my $self = bless {
    id => $id,
    vpn => $vpn_obj,
  }, $class;

  if (! defined $self->{id}) {
    $self->_vnc_dir($vpn_obj)->mkpath();
    for($self->{id} = 0;;$self->{id} += 1) {
      my $attempt_data_dir = $self->data_dir;
      mkdir($attempt_data_dir) && return $self;
      croak "Cannot create $attempt_data_dir: $!" unless
        ($! == EEXIST);
    }
  }

  return $self;
}

sub all {
  my ($class, $vpn_obj) = @_;
  return $class->_load_from_subdirs($class->_vnc_dir($vpn_obj), $vpn_obj);
}

sub TO_JSON {
  my ($self) = @_;
  # The id is denormalized for the view's comfort and also for
  # ->all_json to make sense.
  return { id => $self->{id}, name => $self->{name}, desc => $self->{desc},
           ip => $self->{ip}, port => $self->{port} };
}

sub _vnc_dir {
  my (undef, $vpn_obj) = @_;
  return io->dir($vpn_obj->data_dir)->catdir("vncs")
}

sub data_dir {
  my $self = shift;
  return $self->_vnc_dir($self->{vpn})->catdir($self->{id});
}

__PACKAGE__->mk_accessors(qw(name desc ip port));

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
  my $vnc1 = EPFLSTI::BlueBox::VNCTarget->new($vpn, 1);
  $vnc1->{desc} = "Hello.";
  $vnc1->save();
  my $vnc2 = EPFLSTI::BlueBox::VNCTarget->new($vpn, 2);

  my $json = io->pipe($synopsis)->slurp;
  ok ((my $results = JSON::decode_json($json)),
      "Tastes like JSON");

  my @results = sort { $a->{id} cmp $b->{id} } @$results;

  is_deeply(\@results, [{id => 1, desc => "Hello."},
                        {id => 2, desc => undef}]);
};

