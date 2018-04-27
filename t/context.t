#!perl

use strict;
use warnings;
use Test::More;

use TaskMaster::Context;

{
  my $ctx = TaskMaster::Context->new;
  $ctx->task( "hello", sub { $done++ } );
  $ctx->run_task("hello");
  $ctx->run_task("hello");
  is $done, 1, "run once";
}

ok 1, "that's ok";

done_testing;

# vim:ts=2:sw=2:et:ft=perl

