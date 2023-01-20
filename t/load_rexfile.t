#!/usr/bin/env perl

use 5.010001;
use strict;
use warnings;
use autodie;
use re '/msx';

our $VERSION = '9999.99.99_99'; # VERSION

use Test::More tests => 21;

use File::Spec;
use File::Temp;
use Rex::CLI;
use Rex::Commands::File;
use Test::Output;

## no critic (DuplicateLiteral);

$Rex::Logger::format   = '%l - %s';
$Rex::Logger::no_color = 1;

my $testdir      = File::Spec->join( 't', 'rexfiles' );
my $rex_cli_path = $INC{'Rex/CLI.pm'};
my $empty        = q();

my ( $exit_was_called, $expected );

local *Rex::CLI::exit = sub { $exit_was_called = 1 };

my $logfile = File::Temp->new->filename;
Rex::Config->set_log_filename($logfile);

# NOW TEST

# No Rexfile warning (via Rex::Logger)
my $rexfile = File::Spec->join( $testdir, 'no_Rexfile' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'No Rexfile console output';

is( $exit_was_called, $expected->{exit}, 'No Rexfile exit status' );
is( cat($logfile),    $expected->{log},  'No Rexfile warning (via logger)' );

# Valid Rexfile
$rexfile = File::Spec->join( $testdir, 'Rexfile_noerror' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Valid Rexfile console output';

is( $exit_was_called, $expected->{exit}, 'Valid Rexfile exit status' );
is( cat($logfile), $expected->{log},
  'No warnings on valid Rexfile (via logger)' );

# Rexfile with warnings
$rexfile = File::Spec->join( $testdir, 'Rexfile_warnings' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Rexfile with warnings console output';

is( $exit_was_called, $expected->{exit}, 'sub load_rexfile() not exit' );
is( cat($logfile),    $expected->{log},  'Warnings present (via logger)' );

# Rexfile with fatal errors
$rexfile = File::Spec->join( $testdir, 'Rexfile_fatal' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Rexfile with errors console output';

is( $exit_was_called, $expected->{exit}, 'sub load_rexfile() aborts' );
is( cat($logfile),    $expected->{log},  'Errors present (via logger)' );

# Now print messages to STDERR/STDOUT
# Valid Rexfile
$rexfile = File::Spec->join( $testdir, 'Rexfile_noerror_print' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Valid Rexfile with messages console output';

is( $exit_was_called, $expected->{exit}, 'Valid Rexfile messages exit status' );
is( cat($logfile), $expected->{log},
  'No warnings via logger on valid Rexfile that print messages' );

# Rexfile with warnings
$rexfile = File::Spec->join( $testdir, 'Rexfile_warnings_print' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Rexfile with warnings and messages console output';

is( $exit_was_called, $expected->{exit},
  'Rexfile warnings messages exit status' );
is( cat($logfile), $expected->{log}, 'Code warnings exist via logger' );

# Rexfile with fatal errors
$rexfile = File::Spec->join( $testdir, 'Rexfile_fatal_print' );

_setup_test();

output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
  $expected->{stderr}, 'Rexfile with errors and messages console output';

is( $exit_was_called, $expected->{exit}, 'sub load_rexfile() aborts' );
is( cat($logfile),    $expected->{log},  'Fatal errors exist via logger' );

sub _setup_test {
  Rex::TaskList->create->clear_tasks();

  $exit_was_called = 0;

  $expected->{exit} = $rexfile =~ qr{fatal} ? 1 : 0;

  for my $extension (qw(log stdout stderr)) {
    my $file            = "$rexfile.$extension";
    my $default_content = $extension eq 'stderr' ? $expected->{log} : $empty;

    $expected->{$extension} = -r $file ? cat($file) : $default_content;
    $expected->{$extension} =~ s{%REX_CLI_PATH%}{$rex_cli_path};
  }

  # reset log
  open my $fh, '>', $logfile;
  close $fh;

  # reset require
  delete $INC{'__Rexfile__.pm'};

  return;
}
