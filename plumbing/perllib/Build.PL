# At this point, this Build.PL is mostly used to run the test suite.

use FindBin;
use lib "$FindBin::Bin/../../devsupport/perllib";
use My::Module::Build;

my $build = My::Module::Build->new
  (
   module_name => 'EPFLSTI::BlueBox',
   dist_version => '0.01',
   dist_author => 'Dominique Quatravaux <dominique.quatravaux@epfl.ch>',
   dist_abstract => q(EPFL's CMi Blue Box Network Operations Center),
   license  => 'perl',
   requires => {
     'perl'          => '>= 5.10.0',      # need to die with a ref
     'Future'        => '>= 0.30',   # need Future->done as class method
     'IO::All'       => '>= 0.0',
     'IO::Async'     => '>= 0.0',
     'JSON'          => '>= 0.0',
     'List::Util'    => '>= 0.0',
     'Log::Message'  => '>= 0.0',
     'Scalar::Util'  => '>= 0.0',
     'Set::Scalar'   => '>= 0.0',
     'Try::Tiny'     => '>= 0.0',
   },
   build_requires => {
     'Test::More'  => '>= 0.0',
     'Test::Group' => '>= 0.19',
     My::Module::Build->requires_for_build(),
   },
   test_files_in_directories => ['EPFLSTI', '../../devsupport/perllib'],
  );
$build->create_build_script;
