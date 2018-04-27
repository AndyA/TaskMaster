package TaskMaster::Step;

our $VERSION = "0.01";

use v5.10;

use Moose;

use Carp qw( croak );

=head1 NAME

TaskMaster::Step - A task step

=cut

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ['deps', 'desc'] => (
  is       => 'ro',
  isa      => 'ArrayRef[Str]',
  required => 1,
  default  => sub { [] },
);

has opts => (
  is       => 'ro',
  isa      => 'ArrayRef[HashRef]',
  required => 1,
  default  => sub { [] },
);

has code => (
  is       => 'ro',
  isa      => 'ArrayRef[CodeRef]',
  required => 1,
  default  => sub { [] },
);

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
