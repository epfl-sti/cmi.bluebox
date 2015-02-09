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

sub import {
  my $unused_class = shift;
  if ($_[0] && $_[0] eq "-main") {
    shift;
    if (! -d "/srv/log") {
      mkdir("/srv/log") or die qq'Cannot mkdir("/srv/log"): $!';
    }
    my $logfile = "/srv/log/" . shift . ".$$.log";
    open(STDERR, ">", $logfile) or die "Cannot log to $logfile: $!";
    open(STDOUT, ">&2") or die "Cannot dup STDOUT to STDERR: $!";
    local $Log::Message::Simple::MSG_FH = \*STDERR;
    local $Log::Message::Simple::ERROR_FH = \*STDERR;
    local $Log::Message::Simple::DEBUG_FH = \*STDERR;
  }
  my $caller = (caller())[0];
  sub msg {
    Log::Message::Simple::msg(sprintf("[%s %s] %s",
                                      $caller, scalar(localtime), $_[0]),
                              1);
  }
  { no strict "refs"; *{"${caller}::msg"} = \&msg; }
}

1;
