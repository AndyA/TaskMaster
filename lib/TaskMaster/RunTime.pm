package TaskMaster::RunTime;

our $VERSION = "0.01";

use v5.10;

use Moose;

use Carp qw( croak );

use TaskMaster::Context;
use TaskMaster::Step;

=head1 NAME

TaskMaster::RunTime - TaskMaster runtime engine

=cut

has ['_tasks', '_done', '_context'] => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

has _context => (
  is      => 'rw',
  isa     => 'TaskMaster::Context',
  default => sub {
    TaskMaster::Context->new( name => "<ROOT>", depth => 0, rt => shift );
  },
  handles => ['is_dirty', 'matches'],
);

has '_at_exit' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
  handles => { defer => 'unshift' },
);

has '_dirty' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

has force => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub dirty {
  my $self  = shift;
  my $dirty = $self->_dirty;
  $dirty->{$_}++ for @_;
  return $self;
}

sub dirty_list { sort keys %{ shift->_dirty } }

sub flatten {
  my $self = shift;
  map { ref $_ && "ARRAY" eq ref $_ ? $self->flatten(@$_) : $_ } @_;
}

sub step_from_args {
  my $self = shift;
  my $name = shift;
  my @code = ();
  my @deps = ();
  my @desc = ();
  my @opts = ();

  for my $arg (@_) {
    unless ( ref $arg ) { push @desc, $arg; next }
    if ( "ARRAY" eq ref $arg ) { push @deps, $self->flatten($arg); next }
    if ( "HASH" eq ref $arg ) { push @opts, {%$arg}; next }
    if ( "CODE" eq ref $arg ) { push @code, $arg; next }
    croak "Bad arg";
  }

  return TaskMaster::Step->new(
    name => $name,
    deps => \@deps,
    desc => \@desc,
    opts => \@opts,
    code => \@code
  );
}

sub task {
  my $self = shift;
  my $name = shift;

  push @{ $self->_tasks->{$name} }, $self->step_from_args( $name, @_ );

  return $self;
}

sub _push_context {
  my ( $self, $name ) = @_;

  my $parent = $self->_context;

  my $ctx = TaskMaster::Context->new(
    parent => $parent,
    name   => $name,
    depth  => $parent->depth + 1,
    rt     => $self,
  );

  $self->_context($ctx);
  return $ctx;
}

sub _pop_context {
  my $self = shift;
  $self->_context( $self->_context->parent );
}

sub run_task {
  my $self = shift;
  my $name = shift;

  return if $self->_done->{$name}++;
  my $task = $self->_tasks->{$name};

  croak "No task $name"
   unless defined $task;

  for my $step (@$task) {
    my $ctx = $self->_push_context($name);
    $ctx->run_step($step);
    $self->_pop_context;
  }
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
