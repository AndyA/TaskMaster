#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;

use TaskMaster::RunTime;

my @names = qw(
 lib/TaskMaster.pm
 lib/TaskMaster/Context.pm
 lib/TaskMaster/Glob.pm
 lib/TaskMaster/RunTime.pm
 lib/TaskMaster/Step.pm
 ref/config.ini
 t/glob.t
 t/runtime.t
 dist.ini
 paths
);

{
  my $rt   = TaskMaster::RunTime->new;
  my $done = 0;
  $rt->task( "hello", sub { $done++ } );
  $rt->run("hello");
  $rt->run("hello");
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

{
  my $rt     = TaskMaster::RunTime->new;
  my @ignore = ();

  my $handler = sub {
    my $ctx = shift;
    push @ignore, $ctx->name;
    for my $code ( 1 .. 6 ) {
      push @ignore, $code if $ctx->should_ignore($code);
    }
  };

  $rt->task( "none", $handler );
  $rt->task( "all", { ignore => [1 .. 6] }, $handler );
  $rt->task( "odd", { ignore => [1, 5] }, { ignore => [3] }, $handler );
  $rt->task(
    "even",
    ["all", "none", "odd"],
    { ignore => [2, 4, 6] }, $handler
  );

  $rt->run_task("even");
  eq_or_diff [@ignore],
   ["all", 1, 2, 3, 4, 5, 6, "none", "odd", 1, 3, 5, "even", 2, 4, 6],
   "ignore: correct codes ignored";
}

{
  my $rt   = TaskMaster::RunTime->new;
  my @done = ();

  my $handler = sub {
    my $ctx = shift;
    # Try enough match - which shouldn't polute matches
    my @t = $ctx->is_dirty("**/*.t");
    push @done, $ctx->name, [$ctx->matches], [@t];
  };

  $rt->dirty(@names);

  $rt->task( "pm",  { changed => "**/*.pm" }, $handler );
  $rt->task( "ini", { changed => "*.ini" },   $handler );
  $rt->task( "cc",  { changed => "**/*.c" },  $handler );
  $rt->task( "default", ["pm", "ini", "cc"] );

  $rt->run;

  my @t = grep { /\.t$/ } @names;

  eq_or_diff [@done],
   ['pm', [grep { /\.pm$/ } @names], [@t], 'ini', ['dist.ini'], [@t]],
   "glob: expected tasks run";
}

{
  my $rt      = TaskMaster::RunTime->new;
  my @done    = ();
  my $handler = sub { push @done, shift->name };

  $rt->task( "setup",    $handler );
  $rt->task( "cleanup",  $handler );
  $rt->task( "complete", $handler );
  $rt->task(
    "lifecycle",
    ["setup"],
    sub {
      my $ctx = shift;
      $ctx->defer( "cleanup", "complete" );
      $handler->($ctx);
    }
  );

  $rt->task( "default", ["lifecycle"] );

  $rt->run;

  eq_or_diff [@done], ["setup", "lifecycle", "cleanup", "complete"],
   "defer: tasks run";
}

{
  # Logging
  my $rt = TaskMaster::RunTime->new;

  my %log_levels = (
    debug   => 0,
    verbose => 1,
    mention => 2,
    warning => 3,
    error   => 4,
  );

  while ( my ( $name, $level ) = each %log_levels ) {
    $rt->log_level($name);
    is $rt->log_level, $level, "log level $name is $level";
    $rt->log_level($level);
    is $rt->log_level, $level, "log level is $level";
  }
}

done_testing;

# vim:ts=2:sw=2:et:ft=perl

