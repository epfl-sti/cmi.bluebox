#!/usr/bin/perl -w

use strict;

=head1 NAME

init.pl – Process number 1 in the Docker container

=head1 DESCRIPTION

Start tinc and the Web UI.

=cut

## Uncomment this to get early warnings about syntax errors etc:
# BEGIN { open(STDERR, ">", "/srv/init.err"); }

use EPFLSTI::Docker::Log -main => "init.pl";

use EPFLSTI::Docker::Init;

init_sequence {
  run_command("/opt/blueboxnoc/plumbing/firsttime.pl")
    ->when_done
    ->then(sub {
      run_command("/etc/init.d/tinc", "start")
        ->when_done
    })
    ->then(sub {
      run_daemon("node", "/opt/blueboxnoc/blueboxnoc-ui/bin/www")
        ->when_ready(qr/ready|serving|running|Listening/i)
    })
    # apache comes last, so that the world never sees a half-running system.
    ->then(sub {
      run_command("/etc/init.d/apache2", "start")
        ->when_done
    })
}
