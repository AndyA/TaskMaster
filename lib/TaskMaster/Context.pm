package TaskMaster::Context;

our $VERSION = "0.01";

use v5.10;

use Moose;

use Carp qw( croak );

=head1 NAME

TaskMaster::Context - A runtime context

=cut

has ['_tasks', '_done', '_context'] => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

has _context => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub { {} }
);

has '_at_exit' => (
  traits  => ['Array'],
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { {} }
);

has force => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

sub task {
  my $self = shift;
  my $name = shift;
  my @code = ();
  my @deps = ();
  my @desc = ();
  my @opts = ();

  for my $arg (@_) {
    unless ( ref $arg )            { push @desc, $arg;          next }
    if     ( "ARRAY" eq ref $arg ) { push @deps, flatten($arg); next }
    if     ( "HASH" eq ref $arg )  { push @opts, $arg;          next }
    if     ( "CODE" eq ref $arg )  { push @code, $arg;          next }
    croak "Bad arg";
  }

  push @{ $self->_tasks->{$name} },
   { deps => \@deps, desc => \@desc, opts => \@opts, code => \@code };

  return $self;
}

sub defer {
  my $self = shift;
  unshift @{ $self->_at_exit }, @_;
  return $self;
}

sub dirty {
}

sub run_task {
  my $self  = shift;
  my $name  = shift;
  my $depth = shift // 0;

  return if $self->_done->{$name}++;
  my $task = $self->_tasks->{$name};

  croak "No task $name"
   unless defined $task;

  my $ctx = { parent => $self->_context, name => $name, depth => $depth };

  #  my $pad = $O{verbose} ? "  " x $depth : "";
  #  my $desc = sprintf "[%3d] %-$st->{max_name}s :", $depth, $name;

  #  say "# ", colored( ["cyan"], "${desc}${pad} BEGIN" ) if $O{verbose};

  for my $step (@$task) {
    #    local %ignore = ();
    my $run_me = 1;
    for my $opt ( @{ $step->{opts} } ) {
      unless ( $self->force ) {
        if ( ( $opt->{if} && !$opt->{if}($st) )
          || ( $opt->{changed} && !is_dirty( @{ $opt->{changed} } ) ) ) {
          $run_me = 0;
          last;
        }
      }
      if ( $opt->{ignore} ) {
        #        $ignore{$_}++ for flatten( $opt->{ignore} );
      }
    }

    if ($run_me) {
      for my $dep ( @{ $step->{deps} } ) {
        run_task( $st, $dep, $depth + 1 );
      }
      my @code = @{ $step->{code} };
      if (@code) {
        my @d = @{ $step->{desc} };
 #        say "# ", colored( ["cyan"], "${desc}${pad} ", join( " ", @d ) ) if @d;
        $_->($st) for @code;
      }
    }
  }

  #  say "# ", colored( ["cyan"], "${desc}${pad} BEGIN" ) if $O{verbose};
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
