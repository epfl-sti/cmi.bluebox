#!/usr/bin/perl -w

use strict;

=head1 NAME

EPFLSTI::Docker::Log - Log from inside a Docker container

=head1 SYNOPSIS

  use EPFLSTI::Docker::Log -main => "firsttime.pl";

  msg "Kilroy was there";

=head1 DESCRIPTION

Use L<Log::Message::Simple> to log to a file in /srv/log, and also
redirect STDOUT and STDERR.

=cut

package EPFLSTI::Docker::Log;

use Log::Message::Simple qw(error);
use FileHandle;

sub import {
  my $unused_class = shift;
  if ($_[0] && $_[0] eq "-main") {
    shift;
    my $logfile = logfile_path(shift, $$);
    open(STDERR, ">", $logfile) or die "Cannot log to $logfile: $!";
    open(STDOUT, ">&2") or die "Cannot dup STDOUT to STDERR: $!";
    local $Log::Message::Simple::MSG_FH = \*STDERR;
    local $Log::Message::Simple::ERROR_FH = \*STDERR;
    local $Log::Message::Simple::DEBUG_FH = \*STDERR;
    ## Just for fun, this works:
    # import(); msg("Logging to $logfile");
  }
  my ($callpkg, undef, $callline) = caller;
  my $msg = sub {
    my $txtmsg = sprintf(
      "[%s:%s %s] %s",
      $callpkg, $callline, scalar(localtime), $_[0]);
                              
    Log::Message::Simple::msg($txtmsg, 1);
  };
  { no strict "refs"; *{"${callpkg}::msg"} = $msg; }
}

=head2 log_dir

=head2 log_dir ($set_log_dir)

Get or set the top-level directory where all log files go. By default
this is /srv/log in production, and guessed in development.

=cut

sub _is_prod {
  if ($^O ne "linux") { return 0; }
  if ($0 =~ m|/Users/| or $0 =~ m|/home/|) { return 0; }
  if ($0 =~ m|^/opt|) { return 1; }
  return undef;
}

our $_log_dir;

sub log_dir {
  if (@_) {
    $_log_dir = $_[0];
    return;
  }
  if ($_log_dir) {
    return $_log_dir;
  }

  if  (_is_prod) {
    $_log_dir = "/srv/log";
  } else {
    require File::Spec;
    require File::Basename;
    my $scriptdir = File::Spec->rel2abs(File::Basename::dirname($0));
    chomp(my $checkoutdir = `set +x; cd "$scriptdir"; git rev-parse --show-toplevel`);
    if ($checkoutdir) {
      $_log_dir = "$checkoutdir/var/log";
    } else {
      require File::Temp;
      $_log_dir = File::Temp::tempdir("EPFL-Docker-Log-XXXXXX", TMPDIR => 1 );
    }
    warn "Logging to $_log_dir for development\n";
  }
  return $_log_dir;
}


our $_path_created;
sub logfile_path {
  my ($processname, $pid, $suffix) = @_;
  if (! defined $suffix) { $suffix = ".log"; }
  my $log_dir = log_dir();
  if (! $_path_created) {
    if (! -d $log_dir) {
      require File::Path;
      File::Path::make_path($log_dir);
    }
    $_path_created = 1;
  }
  return "${log_dir}/${processname}.${pid}${suffix}";
}

1;
