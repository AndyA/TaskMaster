#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;

use TaskMaster::Glob;

my @names = qw(
 lib/TaskMaster/Context.pm
 lib/TaskMaster/RunTime.pm
 lib/TaskMaster/Glob.pm
 lib/TaskMaster/Step.pm
 lib/TaskMaster.pm
 ref/config.ini
 t/glob.t
 t/runtime.t
 dist.ini
 paths
);

my @case = (
  { name    => "match all",
    pattern => ["**"],
    want    => [@names],
  },
  { name    => "match .pm",
    pattern => ["**/*.pm"],
    want    => [grep { /\.pm$/ } @names],
  },
  { name    => "dist.ini",
    pattern => ["dist.ini"],
    want    => ["dist.ini"],
  },
  { name    => "*.ini",
    pattern => ["*.ini"],
    want    => ["dist.ini"],
  },
  { name    => "**/*.ini",
    pattern => ["**/*.ini"],
    want    => [grep { /\.ini$/ } @names],
  },
  { name    => "*.c",
    pattern => ["*.c"],
    want    => [],
  },
);

for my $case (@case) {
  my $name = $case->{name};
  my $glob = TaskMaster::Glob->new( pattern => $case->{pattern} );
  my @got  = $glob->match(@names);
  eq_or_diff [@got], $case->{want}, "$name: got expected matches";
}

ok 1, "that's ok";

done_testing;

# vim:ts=2:sw=2:et:ft=perl

