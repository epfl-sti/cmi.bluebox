#!/usr/bin/perl -w

package EPFLSTI::Async::NewFileStream;

use strict;

=head1 NAME

EPFLSTI::Async::NewFileStream

=head1 DESCRIPTION

Like L<IO::Async::FileStream>, except don't complain if the file
doesn't exist at once.

=cut

use base qw(IO::Async::FileStream);

=begin internals

=head2 _init

Overridden to replace the C<< ->{file} >> with an instance of
L</EPFLSTI::Async::NewFileStream::_NewFile>.

=cut

sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->remove_child($self->{file});
  # Cargo-culted from the superclass, with only the class name s///'d:
  $self->add_child($self->{file} =
    EPFLSTI::Async::NewFileStream::_NewFile->new(
      on_devino_changed => $self->_replace_weakself( 'on_devino_changed' ),
      on_size_changed   => $self->_replace_weakself( 'on_size_changed' ),
     ));
}

=head2 on_size_changed

=head2 on_devino_changed

Overridden to restore the superclass invariants, i.e. $self->{last_size}
should be defined.

=cut

sub on_size_changed {
  my $self = shift;
  $self->{last_size} ||= 0;
  return $self->SUPER::on_size_changed(@_);
}

sub on_devino_changed {
  my $self = shift;
  $self->{last_size} ||= 0;
  return $self->SUPER::on_devino_changed(@_);
}

=head2 read_more

Overridden to always run at top-level context wrt $self->loop.

I found this weird bug whence L<IO::Async::Timer::Periodic/_make_cb>
assumes that it can unconditionnally $self->start (line 229 of
IO::Async::Timer::Periodic $VERSION=0.64), relying on the fact that it
deleted the ->{id} (which is the same as ->stop()ping) on line 224.
Unfortunately in between there is line 226, which calls the on_tick
handler, which may call e.g. the on_devino_changed handler
(IO::Async::File line), which may call
L<IO::Async::FileStream/read_more>, which may start the timer
(IO::Async::FileStream line 197) if the ->{file} transitions from !
->{want_read} to ->{want_read}. (The latter is never the case in
vanilla L<IO::Async::FileStream>, because it assumes that the tailed
log file always exists; hence ->{want_read} starts true at
construction time, and stays so forever, and the return path on line
535 of L<IO::Async::Handle> is always taken, masking the bug since
line 545 is never called.)

The workaround is to just defer the call to read_more() outside of any
(involuntary) critical section, using $self->loop->later.

=cut

sub read_more {
  my $self = shift;
  $self->loop->later( sub { $self->SUPER::read_more } );
}


=head2 read_handle

Overridden to be $self->{file}->handle, which (unlike with
L<IO::Async::File>) may change over time.

=cut

sub read_handle {
  my $self = shift;
  return $self->{file}->handle;
}

=head1 EPFLSTI::Async::NewFileStream::_NewFile

Like L<IO::Async::File>, except don't complain if/when the file
doesn't exist.

=cut

package EPFLSTI::Async::NewFileStream::_NewFile;

use base qw(IO::Async::File);
use Carp;
use Errno;
use FileHandle;
use File::stat;

=head2 configure

The superclass will only ever see handles, not the file name.

=cut

sub configure
{
  my $self = shift;
  my %params = @_;

  if (exists $params{filename}) {
    $self->{EPFLSTI_Async_NewFileStream__filename} = delete $params{filename};
    $self->_EPFLSTI__Async_NewFileStream__watch_file();
  }
  $self->SUPER::configure(%params);
}

=head2 on_tick

Overridden to call L</_EPFLSTI__Async_NewFileStream__watch_file>, and
do nothing if we don't have a handle yet.

=cut

sub on_tick {
  my $self = shift;
  $self->_EPFLSTI__Async_NewFileStream__watch_file();
  return if ! $self->{handle};
  $self->SUPER::on_tick();
}

=head2 _EPFLSTI__Async_NewFileStream__watch_file

Private method (hence the name) to open or rotate C<< $self->{handle} >>
when needed.

=cut

sub _EPFLSTI__Async_NewFileStream__watch_file {
  my $self = shift;

  my $filename = $self->{EPFLSTI_Async_NewFileStream__filename} or return;
  my $new = stat($filename) or return;

  if (my $old = $self->{last_stat}) {
    return unless ( $old->dev != $new->dev or $old->ino != $new->ino );
  }

  # Mind the race, this could still fail if the file gets rotated now.
  return unless my $newhandle = FileHandle->new($filename, "r");

  $self->{handle} = $newhandle;
  # Upon first open, need to restore the superclass invariants:
  $self->{last_stat} ||= stat $self->{handle};
}

=head2 _reopen_file

Neutered because the superclass assumes $self->{filename}.

Superseded by L</_EPFLSTI__Async_NewFileStream__watch_file> anyway.

=cut

sub _reopen_file {}

=head2 _add_to_loop

Overridden to tolerate the state where we don't have a C<< ->{handle} >> yet.

=cut

sub _add_to_loop
{
  my $self = shift;
  return $self->IO::Async::Timer::Periodic::_add_to_loop( @_ );
}

=end internals

=cut

require My::Tests::Below unless caller();

# To run the test suite:
#
# perl -Iplumbing/perllib -Idevsupport/perllib \
#   plumbing/perllib/EPFLSTI/Async/NewFileStream.pm

__END__

use Test::More qw(no_plan);
use Test::Group;
use IO::Async::Test;

use Carp 'verbose';

use File::Spec::Functions qw(catfile);
use File::stat;

use IO::Async::Loop;

sub touch ($) {
  my ($file) = @_;
  # We don't actually need touch() to not truncate the file anywhere
  # in the tests. Also, opening ">>" without writing anything doesn't
  # seem to update the mtime, which we do need.
  open(NOTHING, ">", $file) or die "Cannot touch $file: $!";
  close(NOTHING);
}

sub echo ($$) {
  my ($file, $text) = @_;
  open(SOMETHING, ">>", $file) or die "Cannot open $file: $!";
  chomp($text); $text .= "\n";
  print SOMETHING $text or die "Cannot write to file $file: $!";
  close(SOMETHING)  or die "Cannot close file $file: $!";
}

test "EPFLSTI::Async::NewFileStream::_NewFile" => sub {
  my $loop = new_builtin IO::Async::Loop;
  testing_loop($loop);

  my $testfile = catfile(My::Tests::Below->tempdir, "arlesienne");

  my $on_mtime_changed = my $on_devino_changed = sub {fail "Too soon"};
  my $f = EPFLSTI::Async::NewFileStream::_NewFile->new(
    filename => $testfile,
    on_mtime_changed => sub { $on_mtime_changed->() },
    on_devino_changed => sub { $on_devino_changed->() },
    interval => 0.1
    );
  $loop->add($f);
  pass "Survived not having a handle";

  $loop->await($loop->delay_future(after => 0.5));
  pass "Survived doing nothing for more than one tick";
  is $f->{handle}, undef;

  touch $testfile;
  wait_for {$f->{handle}};
  my $handlestat = stat $f->{handle};
  my $filestat = stat $testfile;
  is($handlestat->dev, $filestat->dev);
  is($handlestat->ino, $filestat->ino);

  # Note: we need to ensure that the mtime will change, and it has a
  # resolution of one second.
  $loop->await($loop->delay_future(after => 1.1));
  pass "Handlers shouldn't fire yet";

  my $mtime_changed;
  $on_mtime_changed = sub {$mtime_changed = 1};
  touch $testfile;
  wait_for { $mtime_changed };

  $mtime_changed = 0;
  rename($testfile, "$testfile.rotate");
  $loop->await($loop->delay_future(after => 1.1));
  touch "$testfile.rotate";
  wait_for { $mtime_changed };

  my $devino_changed;
  $on_devino_changed = sub {$devino_changed = 1};
  touch $testfile;
  wait_for { $devino_changed };

  $handlestat = stat $f->{handle};
  $filestat = stat $testfile;
  is($handlestat->dev, $filestat->dev);
  is($handlestat->ino, $filestat->ino);
};

test "EPFLSTI::Async::NewFileStream" => sub {
  my $loop = new_builtin IO::Async::Loop;
  testing_loop($loop);

  my $testfile = catfile(My::Tests::Below->tempdir, "fakelogfile");
  my $on_read = sub {fail "on_read too soon"};
  my $on_truncated = sub {fail "on_truncated too soon"};

  my $f = EPFLSTI::Async::NewFileStream->new(
    filename => $testfile,
    on_read => sub { $on_read->(@_) },
    on_truncated => sub { $on_truncated->(@_) },
    on_initial => sub { fail "on_initial souldn't be called in this test" },
    );
  $f->{file}->configure(interval => 0.1);  # Speed up this test
  $loop->add($f);

  $loop->await($loop->delay_future(after => 0.5));
  pass("At first, nothing happens");

  touch $testfile;
  $loop->await($loop->delay_future(after => 0.5));
  pass("Still nothing");

  my $aha;
  $on_read = sub {
    my (undef, $bufref) = @_;
    $aha = 1 if $$bufref =~ m/Aha!\n/;
    $$bufref = "";
    return 0;
  };
  # Timestamp needs to change for the writes to be picked up:
  $loop->await($loop->delay_future(after => 1.1));
  is $aha, undef;
  echo $testfile, "Aha!";
  wait_for { $aha };

  $aha = 0;
  rename($testfile, "$testfile.rotated");
  $loop->await($loop->delay_future(after => 1.1));
  is $aha, 0;
  echo "$testfile.rotated", "More Aha!";
  wait_for { $aha};
  pass("Follows the old file during rotation");

  # Doesn't need a delay here since dev / ino will change.
  $aha = 0;
  my $truncated;
  $on_truncated = sub { $truncated = 1};
  echo $testfile, "Rotated Aha!";
  wait_for { $aha && $truncated };
  pass("Switches over to rotated file");
};

test "EPFLSTI::Async::NewFileStream on existing file" => sub {
  my $testfile = catfile(My::Tests::Below->tempdir, "fakelogfile_big");
  echo $testfile, "log" for (1..10);

  my $loop = new_builtin IO::Async::Loop;
  testing_loop($loop);

  my $on_initial;
  my $f = EPFLSTI::Async::NewFileStream->new(
    filename => $testfile,
    on_read => sub {},
    on_initial => sub { $on_initial = 1 },
    );
  $loop->add($f);

  wait_for { $on_initial };
  pass "on_initial event called";
};
