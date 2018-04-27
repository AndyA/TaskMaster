#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use lib qw( lib );

use TaskMaster qw( :all );
use TaskMaster::Logger::Console;

rt->logger( TaskMaster::Logger::Console->new );

task ls => "List files" => sub {
  cmd 'ls', '.';
};

task default => ["ls"] => "Say Hello" => sub {
  say "Hello, World";
};

run(@ARGV);

# vim:ts=2:sw=2:sts=2:et:ft=perl

