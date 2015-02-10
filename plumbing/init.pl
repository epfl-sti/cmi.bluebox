#!/usr/bin/perl -w

use strict;

=head1 NAME

init.pl – Process number 1 in the Docker container

=head1 DESCRIPTION

Start tinc and the Web UI.

TODO: monitor subprocesses, restart them, and terminate the whole container if
they can't be kept running.

TONOTDO: turn into systemd-in-Perl.

=cut

use EPFLSTI::Docker::Log -main => "init.pl";

msg "Starting firsttime.pl";
system("/opt/blueboxnoc/plumbing/firsttime.pl");
($? == 0) || exit $?;

msg "Starting tinc";
system("/etc/init.d/tinc", "start");
# Note: until /etc/tinc/nets.boot exists, tinc will not start up.

msg "Starting node";
system("node", "/opt/blueboxnoc/blueboxnoc-ui/helloworld.js");

wait;
