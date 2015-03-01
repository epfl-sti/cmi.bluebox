#!/usr/bin/perl -w

package EPFLSTI::Docker::Paths;

use strict;

use base 'Exporter';

our @EXPORT_OK = qw(srv_dir);

use File::Spec;

=head1 NAME

EPFLSTI::Docker::Paths - Paths on the NOC and Blue Boxes

=head1 DESCRIPTION

Paths in the Blue Box Docker environment are fairly simple; yet we
don't want to hard-code them in order to facilitate development.

=cut

sub _running_within_docker {
  -f "/this_is_docker";
}

our $_srv_dir;
sub srv_dir {
  shift if UNIVERSAL::isa($_[0], __PACKAGE__);
  if (@_) {
    $_srv_dir = shift;
    return;
  } elsif ($_srv_dir) {
    return $_srv_dir;
  } elsif ($ENV{DOCKER_SRVDIR_FOR_TESTS}) {
    $_srv_dir = "$ENV{DOCKER_SRVDIR_FOR_TESTS}";
    warn "Substituting /srv with $_srv_dir for tests\n";
  } elsif (_running_within_docker) {
    $_srv_dir = "/srv";
  } else {
    require File::Basename;
    my $scriptdir = File::Spec->rel2abs(File::Basename::dirname($0));
    chomp(my $checkoutdir = `set +x; cd "$scriptdir";
                             git rev-parse --show-toplevel`);
    if ($checkoutdir) {
      $_srv_dir = "$checkoutdir/var";
      warn "Substituting /srv with $_srv_dir for development\n";
    } else {
      require File::Temp;
      $_srv_dir = File::Temp::tempdir("EPFL-Docker-Log-XXXXXX",
                                      TMPDIR => 1);
      warn "Substituting /srv with $_srv_dir for development\n";
    }
  }
  return $_srv_dir;
}

sub settable_srv_subpath {
  my ($class, $subpath) = @_;

  my ($caller_pkg) = caller();
  my $value;
  return sub {
    shift if UNIVERSAL::isa($_[0], $caller_pkg);
    if (@_) {
      $value = $_[0];
      return;
    } elsif ($value) {
      return $value;
    } else {
      return ($value = File::Spec->catfile(srv_dir(), $subpath));
    };
  }
}

1;
