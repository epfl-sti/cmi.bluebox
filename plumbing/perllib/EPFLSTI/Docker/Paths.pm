#!/usr/bin/perl -w

package EPFLSTI::Docker::Paths;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw(srv_dir);

=head1 NAME

EPFLSTI::Docker::Paths - Paths on the NOC and Blue Boxes

=head1 DESCRIPTION

Paths in the Blue Box Docker environment are fairly simple; yet we
don't want to hard-code them in order to facilitate development.

=cut

sub _is_prod {
  if ($^O ne "linux") { return 0; }
  if ($0 =~ m|/Users/| or $0 =~ m|/home/|) { return 0; }
  if ($0 =~ m|^/opt|) { return 1; }
  return undef;
}

our $_srv_dir;
sub srv_dir {
  if ($_srv_dir) {
    return $_srv_dir;
  }
  if  (_is_prod) {
    return ($_srv_dir = "/srv");
  }

  require File::Spec;
  require File::Basename;
  my $scriptdir = File::Spec->rel2abs(File::Basename::dirname($0));
  chomp(my $checkoutdir = `set +x; cd "$scriptdir"; git rev-parse --show-toplevel`);
  if ($checkoutdir) {
    $_srv_dir = "$checkoutdir/var";
  } else {
    require File::Temp;
    $_srv_dir = File::Temp::tempdir("EPFL-Docker-Log-XXXXXX", TMPDIR => 1 );
  }
  warn "Substituting /srv with $_srv_dir for development\n";
  return $_srv_dir;
}

1;
