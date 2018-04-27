package TaskMaster::Logger::Console;

our $VERSION = "0.01";

use v5.10;

use Moose;
use Term::ANSIColor;
use DateTime;

=head1 NAME

TaskMaster::Logger::Console - Console logger

=cut

my %level_colour = (
  0 => ['red'],
  1 => ['cyan'],
  2 => ['green'],
  3 => ['bright_yellow'],
  4 => ['bright_red'],
);

sub log {
  my ( $self, $level, $ctx, @msg ) = @_;
  my $ts  = DateTime->now->strftime("%Y/%m/%d %H:%M:%S");
  my @col = @{ $level_colour{$level} };
  print colored( [@col, 'on_bright_black'],
    sprintf( "[%3d] %s %-20s", $ctx->depth, $ts, $ctx->name ) ),
   " ",
   colored( [@col], join "", @msg ), "\n";
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
