package EPFLSTI::Async::Tests;

use base 'Exporter';

our @EXPORT = our @EXPORT_OK = qw(await_ok);

use IO::Async::Timer::Periodic;

sub await_ok ($&;$) {
  my ($loop, $sub, $msg) = @_;

  my $timeout = 10;
  my $interval = 0.1;

  my $timedout = Carp::shortmess("await_ok timed out");

  my $done = undef;
  my $timer;
  $timer = IO::Async::Timer::Periodic->new(
    interval => $interval,
    on_tick => sub {
      $timeout -= $interval;
      if ($timeout <= 0) {
        Test::More::fail($timedout);
        $done = 0;
        $loop->stop();
        $timer->stop();
      } elsif ($sub->()) {
        Test::More::pass($msg);
        $done = 1;
        $loop->stop();
        $timer->stop();
      }
    });
  $timer->start();
  $loop->add($timer);
  my $runstatus = $loop->run();
  warn $runstatus if $runstatus;
  Test::More::ok(defined $done);
}

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Idevsupport/perllib devsupport/perllib/EPFLSTI/Async/Tests.pm

__END__

use Test::More qw(no_plan);
use Test::Group;

use IO::Async::Loop;
use EPFLSTI::Async::Tests;

test "await_ok: positive" => sub {
  my $loop = new IO::Async::Loop;
  my $are_we_there_yet = 0;
  my $unused = $loop->delay_future(after => 1)->then(sub {
    $are_we_there_yet = 1;
  });
  await_ok $loop, sub {$are_we_there_yet}, "awaits ok";
};
