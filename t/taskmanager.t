#!perl

use strict;
use warnings;
use Test::More;

use TaskMaster qw( :all );
use Test::Differences;

my @lib_names = qw(
 lib/TaskMaster.pm
 lib/TaskMaster/Context.pm
 lib/TaskMaster/Glob.pm
 lib/TaskMaster/RunTime.pm
 lib/TaskMaster/Step.pm
);

my @other_names = qw(
 ref/config.ini
 t/glob.t
 t/runtime.t
 dist.ini
 paths
);

my @done = ();

my $handler = sub {
  my $ctx = shift;
  push @done, $ctx->name, [matches];
};

task init => sub {
  my $ctx = shift;
  $handler->($ctx);
  dirty @lib_names;
};

task default => ["init"];

run;

eq_or_diff [@done], ['init', []], "tasks run";

done_testing;

# vim:ts=2:sw=2:et:ft=perl

