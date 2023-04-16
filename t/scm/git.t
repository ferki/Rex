#!/usr/bin/env perl

use v5.12.5;
use warnings;

our $VERSION = '9999.99.99_99'; # VERSION

use Test::More tests => 7;
use Test::Exception;

use File::Spec;
use File::Temp qw(tempdir);
use Rex::Commands;
use Rex::Commands::Run;
use Rex::Commands::SCM;
use Rex::Helper::Run;

$Rex::Logger::debug = 1;

my $git = can_run('git');

if ( !defined $git ) {
  plan skip_all => 'Can not find git command';
}

ok( $git, "Found git command at $git" );

my $git_version = i_run 'git version';
ok( $git_version, qq(Git version returned as '$git_version') );

my $test_repo_dir = tempdir( CLEANUP => 1 );
ok( -d $test_repo_dir, "$test_repo_dir is the test repo directory now" );

prepare_test_repo($test_repo_dir);
git_repo_ok($test_repo_dir);

my $test_repo_name = 'test_repo';

subtest 'clone into non-existing directory', sub {
  plan tests => 6;

  my $clone_target_dir = tempdir( CLEANUP => 1 );

  set repository => $test_repo_name, url => $test_repo_dir;

  say i_run 'cd';
  say i_run 'cd', cwd => $clone_target_dir;

  ok( -d $clone_target_dir, "$clone_target_dir could be created" );

  rmdir $clone_target_dir;

  ok( !-d $clone_target_dir, "$clone_target_dir does not exist now" );

  lives_ok { checkout $test_repo_name, path => $clone_target_dir }
  'cloning into non-existing directory';

  git_repo_ok($clone_target_dir);
};

sub prepare_test_repo {
  my $directory = shift;

  i_run qq(git -C $directory init);

  i_run qq(git -C $directory config user.name Rex);
  i_run qq(git -C $directory config user.email noreply\@rexify.org);

  i_run qq(git -C $directory commit --allow-empty -m commit);

  return;
}

sub git_repo_ok {
  my $directory = shift;

  ok( -d $directory, "$directory exists" );
  ok(
    -d File::Spec->join( $directory, q(.git) ),
    "$directory has .git subdirectory"
  );

  lives_ok { i_run qq(git -C $directory rev-parse --git-dir) }
  "$directory looks like a git repository now";

  return;
}
