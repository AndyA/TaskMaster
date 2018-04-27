package TaskMaster::Context;

our $VERSION = "0.01";

use v5.10;

use Moose;

use Carp qw( croak );
use TaskMaster::Glob;

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
  handles =>
   ['force', 'flatten', 'run_task', 'defer', 'dirty', 'dirty_list'],
);

has depth => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
);

has ['_ignored', '_matched'] => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

has _state => (
  is      => 'rw',
  isa     => 'Str',
  default => 'init'
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

sub _set_matched {
  my $self    = shift;
  my $matched = $self->_matched;
  $matched->{$_}++ for @_;
}

sub matches { sort keys %{ shift->_matched } }

sub is_dirty {
  my $self = shift;
  my $glob = TaskMaster::Glob->new( pattern => [$self->flatten(@_)] );
  my @got  = $glob->match( $self->dirty_list );
  $self->_set_matched(@got)
   if $self->_state eq "init";
  return @got;
}

sub _should_run {
  my ( $self, $step ) = @_;

  return 1 if $self->force;

  for my $opt ( @{ $step->opts } ) {
    return
     if exists $opt->{if}
     && !( delete $opt->{if} )->($self);

    return
     if exists $opt->{changed}
     && !$self->is_dirty( delete $opt->{changed} );
  }

  return 1;
}

sub _parse_options {
  my ( $self, $step ) = @_;

  for my $opt ( @{ $step->opts } ) {
    $self->ignore( $self->flatten( delete $opt->{ignore} ) )
     if $opt->{ignore};
  }
}

sub _check_options {
  my ( $self, $step ) = @_;
  my %unk = ();
  $unk{$_}++ for map { keys %$_ } @{ $step->opts };
  croak "Unknown options: ", join( ", ", sort keys %unk )
   if keys %unk;
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
  $self->_state('run');
  $self->_parse_options($step);
  $self->_check_options($step);
  $self->_run_deps($step);

  my @code = @{ $step->code };
  if (@code) {
    #    my @d = @{ $step->desc };
    $_->($self) for @code;
  }
  $self->_state('done');
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
