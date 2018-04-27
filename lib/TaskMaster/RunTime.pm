package TaskMaster::RunTime;

our $VERSION = "0.01";

use v5.10;

use Moose;

use Carp qw( croak );

use TaskMaster::Context;
use TaskMaster::Logger::Null;
use TaskMaster::Step;

=head1 NAME

TaskMaster::RunTime - TaskMaster runtime engine

=cut

has ['_tasks', '_done', 'context'] => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

has context => (
  is      => 'rw',
  isa     => 'TaskMaster::Context',
  default => sub {
    TaskMaster::Context->new( name => "<ROOT>", depth => 0, rt => shift );
  },
  handles => ['is_dirty', 'matches', 'cmd'],
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

has logger => (
  is       => 'rw',
  required => 1,
  default  => sub { TaskMaster::Logger::Null->new },
  handles  => ['log'],
);

has force => (
  is      => 'rw',
  isa     => 'Bool',
  default => 0,
);

with qw(
 TaskMaster::Role::Logging
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

sub task_names { sort keys %{ shift->_tasks } }

sub _push_context {
  my ( $self, $name ) = @_;

  my $parent = $self->context;

  my $ctx = TaskMaster::Context->new(
    parent => $parent,
    name   => $name,
    depth  => $parent->depth + 1,
    rt     => $self,
  );

  $self->context($ctx);
  return $ctx;
}

sub _pop_context {
  my $self = shift;
  $self->context( $self->context->parent );
}

sub has_task {
  my ( $self, $name ) = @_;
  return $self->_tasks->{$name};
}

sub run_task {
  my $self = shift;
  my $name = shift;

  return if $self->_done->{$name}++;
  my $task = $self->has_task($name);

  croak "No task $name"
   unless defined $task;

  $self->verbose("Running $name");
  for my $step (@$task) {
    my $ctx = $self->_push_context($name);
    $ctx->run_step($step);
    $self->_pop_context;
  }

  return $self;
}

sub run {
  my ( $self, @args ) = @_;

  croak "Can't call run inside task"
   if $self->context->depth;

  push @args, "default"
   if !@args && $self->has_task("default");

  $self->run_task($_) for @args;
  $self->run_task($_) for @{ $self->_at_exit };

  return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
