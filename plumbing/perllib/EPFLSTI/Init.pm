#!/usr/bin/perl -w

use strict;

=head1 NAME

EPFLSTI::Init - Support for writing the init.pl script

=head1 SYNOPSIS

  my $loop = IO::Async::Loop

=head1 DESCRIPTION

=cut

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Idevsupport/perllib plumbing/perllib/EPFLSTI/Init.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use Carp;

use IO::Async::Loop;
use IO::Async::Timer::Periodic;

{
  # For some reason, the Carp backtrace logic doesn't work if this is kept in
  # the main package?
  package TestUtils;

  sub await_ok ($&;$) {
    my ($loop, $sub, $msg) = @_;

    my $timeout = 10;
    my $interval = 0.1;

    my $timedout = Carp::shortmess("await_ok timed out");

    my $done = undef;
    my $timer = IO::Async::Timer::Periodic->new(
      interval => $interval,
      on_tick => sub {
        $timeout -= $interval;
        if ($timeout <= 0) {
          Test::More::fail($timedout);
          $loop->stop();
        } elsif ($sub->()) {
          Test::More::ok($msg);
          $loop->stop();
        }
      });
    $timer->start();
    $loop->add($timer);
    $loop->run();
  }
}

BEGIN { *await_ok = \&TestUtils::await_ok; }

test "await_ok: positive" => sub {
  my $loop = new IO::Async::Loop;
  our $are_we_there_yet = 0;
  my $unused = $loop->delay_future(after => 1)->then(sub {
    $are_we_there_yet = 1;
  });
  await_ok $loop, sub {$are_we_there_yet}, "await_ok";
};
