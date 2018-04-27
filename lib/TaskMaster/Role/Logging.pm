package TaskMaster::Role::Logging;

our $VERSION = "0.01";

use v5.10;

use Moose::Role;

use Class::MOP::Method;
use Moose::Util::TypeConstraints;

use Carp qw( croak );
use List::Util qw( min max );

=head1 NAME

TaskMaster::Role::Logging - Logging methods

=cut

my %log_levels = (
  debug   => 0,
  verbose => 1,
  mention => 2,
  warning => 3,
  error   => 4,
);

my $min_level = min values %log_levels;
my $max_level = max values %log_levels;

requires 'log', 'context';

subtype 'TaskMaster::Type::LogLevel' => as 'Int' =>
 where { $_ >= $min_level && $_ <= $max_level } =>
 message { "Invalid log level" };

coerce 'TaskMaster::Type::LogLevel' => from 'Str' =>
 via { _decode_log_level($_) };

has log_level => (
  is       => 'rw',
  isa      => 'TaskMaster::Type::LogLevel',
  coerce   => 1,
  required => 1,
  default  => $log_levels{"mention"},
);

sub _decode_log_level {
  my $level = shift;
  return $level if $level =~ /^\d+$/;
  return $log_levels{ lc $level } // die "Bad log level: $level";
}

my $meta = __PACKAGE__->meta;
while ( my ( $method, $level ) = each %log_levels ) {
  $meta->add_method(
    $method,
    Class::MOP::Method->wrap(
      sub {
        my $self = shift;
        $self->log( $level, $self->context, @_ )
         if $self->log_level <= $level;
      },
      name                 => $method,
      package_name         => __PACKAGE__,
      associated_metaclass => $meta
    )
  );
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
