use 5.010001;
use strict;
use warnings;

use Test::More tests => 4;

use Test::Warnings;

use File::Spec;
use File::Temp;
use Rex::Commands::Fs;

my $fake_file = "file_that_does_not_exist";
eval { Rex::Commands::Fs::stat($fake_file); };
my $err = $@;
like(
  $err,
  qr/^Can't stat $fake_file/,
  "Trying to stat a non-existent file throws an exception"
);

my %path_for = (
  absolute_path => scalar tmpnam(),
  relative_path => 'rex_mkdir_test_sub',

  # unc_path => '\\ComputerName\SharedFolder\Resource',
);

for my $case ( keys %path_for ) {

  subtest "mkdir with $case", sub {
    plan tests => 3;
    my $path = $path_for{$case};

    is( is_dir($path), undef, "$path doesn't exist yet" );

    Rex::Commands::Fs::mkdir($path);
    is( is_dir($path), 1, "$path exists now" );

    rmdir $path;
    is( is_dir($path), undef, "$path doesn't exist anymore" );
  };
}

my $rootdir = File::Spec->rootdir();
Rex::Commands::Fs::mkdir($rootdir);
