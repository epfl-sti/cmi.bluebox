#!/usr/bin/perl -w

package EPFLSTI::Docker::Init;

use strict;

=head1 NAME

EPFLSTI::Docker::Init - Procedural interface for programs run by init.pl

=head1 SYNOPSIS

  use EPFLSTI::Docker::Init qw(init_sequence run_daemon run_command);

  init_sequence {
    run_commmand("/opt/blueboxnoc/plumbing/firsttime.pl")->when_done
      # Just be careful to always return a Future from all the subs.
      ->then(sub {
        run_daemon("/sbin/tincd", "--no-detach")->when_ready(qr/Ready/)
      })
      ->then(sub {
        run_command("/etc/init.d/apache2", "start")->when_done
      })
  };

=cut

use base 'Exporter';

our @EXPORT = our @EXPORT_OK = qw($loop init_sequence run_command run_daemon);

use Future;

use EPFLSTI::Docker::Log;

use IO::Async::Loop;

our $loop;

sub init_sequence (&) {
  my ($code) = @_;

  $loop = new IO::Async::Loop;
  my $future = $code->();
  die "init_sequence block must return a Future object"
    unless UNIVERSAL::isa($future, 'Future');
  $future = $future->then(sub {
    msg("init_sequence complete, watching daemons");
    return Future->done;
  }, sub {
    $loop->stop(shift);
    return Future->done;
  });
  msg "Starting event loop";
  my $parting_words = $loop->run();
  my $state = $future->is_ready? "main loop exiting": "init_sequence failed";
  die "$state: $parting_words";  # Which hopefully we won't
}

sub run_daemon {
  require EPFLSTI::Docker::Init::Daemon;
  my $daemon = EPFLSTI::Docker::Init::Daemon->start($loop, @_);
  my $name = $daemon->process_name;
  msg qq'Started daemon "$name:" ' .
    join(" ", @{$daemon->{process}->{command}});
  return $daemon;
};

sub run_command {
  require EPFLSTI::Docker::Init::Command;
  my $command = EPFLSTI::Docker::Init::Command->start($loop, @_);
  my $name = $command->process_name;
  msg qq'Started command "$name:" ' .
    join(" ", @{$command->{process}->{command}});
  return $command;
};

1;
