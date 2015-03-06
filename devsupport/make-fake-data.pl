#!perl -w

use strict;

=head1 NAME

make-fake-data.pl – Create fake VPNs and Blue Boxes

=head1 SYOPSIS

  perl make-fake-data.pl [<srv_directory>]

=cut

BEGIN {
  use IO::All;
  use File::Basename qw(dirname);
  my $srcdir = io->dir(dirname($0))->dir("..")->absolute;
  unshift @INC, $srcdir . $_ for (qw(/devsupport/perllib /plumbing/perllib));
}

use EPFLSTI::Docker::Paths;

use EPFLSTI::Model::Transaction qw(transaction);

use EPFLSTI::BlueBox::VPN;
use EPFLSTI::BlueBox::BlueBox;
use EPFLSTI::BlueBox::VNCTarget;

if (@ARGV) {
  EPFLSTI::Docker::Paths->srv_dir($ARGV[0]);
}

# Lifted from a former version of api.js, hence the unneeded data.
my $fake_vpn_data =  [
    {name => "Foo", desc => "Foofoo", bbxs => ["bboo", "bbar"]},
    {name => "Bar", desc => "Foobar", bbxs => ["bboo2"]},
    {name => "Bax", desc => "Foobaz", bbxs => ["bbax"]},
    {name => "Bay", desc => "Foobay", bbxs => ["bbay"]},
    {name => "Baz", desc => "Foobaz", bbxs => ["bbaz"]}
];

my $fake_bbx_data = [
    {name => "bboo", vpn => "Foo", desc => "Booboo",
     ip => "192.168.0.1", status => "INIT"},
    {name => "bboo2", vpn => "Bar", desc => "Booboo2",
     ip => "192.168.10.1", status => "INIT"},
    {name => "bbar", vpn => "Foo", desc => "Boobar2",
     ip => "192.168.20.1", status => "DOWNLOADED"},
    {name => "bbax", vpn => "Bax", desc => "Boobax",
     ip => "192.168.30.1", status => "NEEDS_UPDATE"},
    {name => "bbay", vpn => "Bay", desc => "Boobay",
     ip => "192.168.40.1", status => "NEEDS_UPDATE"},
    {name => "bbaz", vpn => "Baz", desc => "Boobaz",
     ip => "192.168.50.1", status => "ACTIVE"}
];

my @fake_vnc_data = (
    {name => "vnc1", ip => "192.168.10.10", port => "5900", vpn => "Foo", desc => "detail of my first vnc", token => "jiy1Wiebo7fa6Taaweesh4nae"},
    {name => "vnc2", ip => "192.168.20.20", port => "5900", vpn => "Bar", desc => "detail of my second vnc", token => "queexahnohyahch3AhceiwooR"},
    {name => "vnc3", ip => "192.168.30.30", port => "5900", vpn => "Bax", desc => "detail of my third vnc", token => "Ahd7heeshoni8phanohB2Siey"},
    {name => "vnc4", ip => "192.168.40.40", port => "5901", vpn => "Bay", desc => "detail of my fourth vnc", token => "saeMohkaec7ax1aichohdoo6u"},
    {name => "vnc5", ip => "192.168.50.50", port => "5901", vpn => "Baz", desc => "detail of my fifth vnc", token => "ooJee6ohwaevooQuoSu3chahk"}
);

transaction {
  foreach my $params (@$fake_vpn_data) {
    EPFLSTI::BlueBox::VPN->new($params->{name})->set_desc($params->{desc});
  }

  foreach my $params (@$fake_bbx_data) {
    my $vpn = EPFLSTI::BlueBox::VPN->load($params->{vpn});
    my $bbox = EPFLSTI::BlueBox::BlueBox->new($params->{name});
    $bbox->set_vpn($vpn);
    $bbox->set_desc($params->{desc});
    $bbox->set_ip($params->{ip});
    $bbox->set_status($params->{status});
  }

  for(my $i = 0; $i < @fake_vnc_data; $i++) {
    my $params = $fake_vnc_data[$i];
    my $vpn = EPFLSTI::BlueBox::VPN->load($params->{vpn});
    my $vnc_target = EPFLSTI::BlueBox::VNCTarget->new($i);
    $vnc_target->set_vpn($vpn);
    $vnc_target->set_name($params->{name});
    $vnc_target->set_desc($params->{desc});
    $vnc_target->set_ip($params->{ip});
    $vnc_target->set_port($params->{port});
  }
};
