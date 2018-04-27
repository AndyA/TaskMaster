#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;

use TaskMaster::RunTime;

{
  my $rt   = TaskMaster::RunTime->new;
  my $done = 0;
  $rt->task( "hello", sub { $done++ } );
  $rt->run_task("hello");
  $rt->run_task("hello");
  is $done, 1, "run once";
}

{
  my $rt      = TaskMaster::RunTime->new;
  my @done    = ();
  my $handler = sub { my $ctx = shift; push @done, $ctx->name };

  $rt->task( "test", $handler );
  $rt->task( "hello", ["test"], $handler );

  $rt->run_task("hello");
  eq_or_diff [@done], ["test", "hello"], "deps: correct tasks run";
  $rt->run_task("hello");
  eq_or_diff [@done], ["test", "hello"], "deps: tasks run only once";
}

{
  my $rt   = TaskMaster::RunTime->new;
  my @done = ();

  $rt->task( "test", sub { push @done, 0 } );
  $rt->task(
    "test",
    { if => sub { 0 }
    },
    sub { push @done, 1 }
  );
  $rt->task(
    "test",
    { if => sub { 1 }
    },
    sub { push @done, 2 }
  );

  $rt->run_task("test");
  eq_or_diff [@done], [0, 2], "if: correct tasks run";
  $rt->run_task("test");
  eq_or_diff [@done], [0, 2], "if: tasks run once only";
}

done_testing;

# vim:ts=2:sw=2:et:ft=perl

