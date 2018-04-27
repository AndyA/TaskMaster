package TaskMaster;

our $VERSION = "1.00";

use v5.10;

use strict;
use warnings;

=head1 NAME

TaskMaster - The TaskMaster task runner

=cut

use base qw( Exporter );

our @EXPORT_OK = qw( rt );
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

sub rt() {
  state $rt;
  return $rt //= TaskMaster::RunTime->new;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
