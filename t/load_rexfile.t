#!/usr/bin/env perl

use 5.010001;
use strict;
use warnings;
use autodie;
use re '/msx';

our $VERSION = '9999.99.99_99'; # VERSION

use Test::More;

use File::Spec;
use File::Temp;
use Rex::CLI;
use Rex::Commands::File;
use Rex::Commands::Fs;
use Test::Output;

$Rex::Logger::format   = '%l - %s';
$Rex::Logger::no_color = 1;

my $testdir      = File::Spec->join( 't', 'rexfiles' );
my $rex_cli_path = $INC{'Rex/CLI.pm'};
my $empty        = q();

my ( $exit_was_called, $expected );

local *Rex::CLI::exit = sub { $exit_was_called = 1 };

my $logfile = File::Temp->new->filename;
Rex::Config->set_log_filename($logfile);

my @rexfiles = grep { !/[.]/ } ls($testdir);
push @rexfiles, 'no_Rexfile';

plan tests => scalar @rexfiles;

for my $rexfile (@rexfiles) {
  subtest "Testing with $rexfile" => sub {
    $rexfile = File::Spec->join( $testdir, $rexfile );

    _setup_test($rexfile);

    output_is { Rex::CLI::load_rexfile($rexfile); } $expected->{stdout},
      $expected->{stderr}, 'Expected console output';

    is( $exit_was_called, $expected->{exit}, 'Expected exit status' );
    is( cat($logfile),    $expected->{log},  'Expected log content' );
  };
}

sub _setup_test {
  my $rexfile = shift;

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
