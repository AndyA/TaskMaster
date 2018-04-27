package TaskMaster::Context;

our $VERSION = "0.01";

use v5.10;

use Moose;

=head1 NAME

TaskMaster::Context - A runtime context

=cut

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has parent => (
  is  => 'ro',
  isa => 'Maybe[TaskMaster::Context]',
);

has rt => (
  is       => 'ro',
  isa      => 'TaskMaster::RunTime',
  required => 1,
  weak_ref => 1,
  handles  => ['force', 'flatten', 'run_task', 'defer', 'dirty'],
);

has depth => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
);

has _ignored => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub ignore {
  my $self = shift;
  $self->_ignored->{$_}++ for @_;
  return $self;
}

sub should_ignore {
  my ( $self, $code ) = @_;
  return exists $self->_ignored->{$code};
}

sub _should_run {
  my ( $self, $step ) = @_;

  return 1 if $self->force;

  for my $opt ( @{ $step->opts } ) {
    return if $opt->{if} && !$opt->{if}($self);
    return if $opt->{changed} && !is_dirty( @{ $opt->{changed} } );
  }

  return 1;
}

sub _parse_options {
  my ( $self, $step ) = @_;

  for my $opt ( @{ $step->opts } ) {
    $self->ignore( $self->flatten( $opt->{ignore} ) )
     if $opt->{ignore};
  }
}

sub _run_deps {
  my ( $self, $step ) = @_;
  for my $dep ( @{ $step->deps } ) {
    $self->run_task($dep);
  }
}

sub run_step {
  my ( $self, $step ) = @_;

  return unless $self->_should_run($step);

  $self->_parse_options($step);
  $self->_run_deps($step);

  my @code = @{ $step->code };
  if (@code) {
    #    my @d = @{ $step->desc };
    $_->($self) for @code;
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
