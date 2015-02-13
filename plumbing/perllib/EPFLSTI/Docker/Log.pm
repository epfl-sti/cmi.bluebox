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

use base 'Exporter';

our @EXPORT = our @EXPORT_OK = qw(msg);

use FileHandle;

use Log::Message::Simple ();

sub import {
  my ($thispkg) = @_;
  if ($_[1] && $_[1] eq "-main") {
    my (undef, $processname) = splice(@_, 1, 2);
    my $logfile = logfile_path($processname, $$);
    open(STDERR, ">", $logfile) or die "Cannot log to $logfile: $!";
    open(STDOUT, ">&2") or die "Cannot dup STDOUT to STDERR: $!";
    $| = 1;
    $Log::Message::Simple::MSG_FH = \*STDERR;
    $Log::Message::Simple::ERROR_FH = \*STDERR;
    $Log::Message::Simple::DEBUG_FH = \*STDERR;
    ## Just for fun, this works:
    # import(__PACKAGE__); msg("Logging to $logfile");
  }
  return $thispkg->export_to_level(1, @_);
}

=head2 msg

Like L<Log::Message::Simple/msg>, only prettier and without the debug flag.

=cut

sub msg {
  my ($msgbody) = @_;
  my ($callpkg, undef, $callline) = caller;
  my $txtmsg = sprintf(
    "[%s line %s %s] %s",
    $callpkg, $callline, scalar(localtime), $msgbody);

  Log::Message::Simple::msg($txtmsg, 1);
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
