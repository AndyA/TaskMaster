package TaskMaster;

our $VERSION = "1.00";

use v5.10;

use strict;
use warnings;

use TaskMaster::RunTime;

=head1 NAME

TaskMaster - The TaskMaster task runner

=cut

use base qw( Exporter );

our @EXPORT_OK = qw(
 rt task dirty is_dirty dirty_list matches run cmd defer
 debug verbose mention warning error
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

sub rt() { state $rt; $rt //= TaskMaster::RunTime->new }

sub task(@)      { rt->task(@_) }
sub dirty(@)     { rt->dirty(@_) }
sub is_dirty(@)  { rt->is_dirty(@_) }
sub dirty_list() { rt->dirty_list }
sub matches()    { rt->matches }
sub run(@)       { rt->run(@_) }
sub cmd(@)       { rt->cmd(@_) }
sub defer(@)     { rt->defer(@_) }
sub debug(@)     { rt->debug(@_) }
sub verbose(@)   { rt->verbose(@_) }
sub mention(@)   { rt->mention(@_) }
sub warning(@)   { rt->warning(@_) }
sub error(@)     { rt->error(@_) }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
