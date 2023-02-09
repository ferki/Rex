use strict;
use warnings;

use Test::More;
use Test::Deep;

use Module::Load::Conditional qw(check_install);
use Rex::Config;
use Rex::Commands;
use Rex::Commands::Run;
use Rex::Transaction;

$::QUIET = 1;

Rex::Config->set_waitpid_blocking_sleep_time(0.001);

my @distributors = ('Base');

if ( check_install( module => 'Parallel::ForkManager' ) ) {
  push @distributors, 'Parallel_ForkManager';
}

plan tests => scalar @distributors * 2;

for my $distributor (@distributors) {
  Rex::Config->set_distributor($distributor);

  for my $autodie ( FALSE, TRUE ) {
    subtest "$distributor distributor with exec_autodie => $autodie" => sub {
      Rex::Config->set_exec_autodie($autodie);
      test_summary();
    };
  }
}

sub create_tasks {
  desc "desc 0";
  task "task0" => sub {
    die "bork0";
  };

  desc "desc 1";
  task "task1" => sub {
    run 'exit 1';
  };

  desc "desc 2";
  task "task2" => sub { };

  desc "desc 3";
  task "task3" => sub {
    transaction {
      do_task qw/task0/;
    };
  };
}

sub test_summary {
  my @expected_summary;

  my %exit_code_for = (
    task0 => 1,
    task1 => Rex::Config->get_exec_autodie() ? 1 : 0,
    task2 => 0,
    task3 => 1,
  );

  $Rex::TaskList::task_list = undef;

  create_tasks();

  for my $task_name ( Rex::TaskList->create->get_tasks ) {
    my %expected_summary_for = (
      $task_name => {
        server    => '<local>',
        task      => $task_name,
        exit_code => $exit_code_for{$task_name},
      },
    );

    Rex::TaskList->run($task_name);
    my @summary = Rex::TaskList->create->get_summary;

    # for the tests we remove the error message.
    for (@summary) {
      delete $_->{error_message};
    }

    push @expected_summary, $expected_summary_for{$task_name};

    my $test_description =
      $expected_summary_for{$task_name}->{exit_code} == 0
      ? "$task_name succeeded"
      : "$task_name failed";

    cmp_deeply \@summary, \@expected_summary, $test_description;
  }

  my $distributor = Rex::Config->get_distributor;
  no warnings;

  @Rex::TaskList::Base::SUMMARY = ();
}
