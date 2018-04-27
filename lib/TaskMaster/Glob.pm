package TaskMaster::Glob;

our $VERSION = "0.01";

use v5.10;

use Moose;

=head1 NAME

TaskMaster::Glob - A glob

=cut

has pattern => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
);

has _re => (
  is      => 'ro',
  isa     => 'RegexpRef',
  lazy    => 1,
  builder => '_b_re',
);

sub _b_re {
  my $self = shift;
  my @all  = ();
  for my $wild ( @{ $self->pattern } ) {
    my @part  = split qr{((?:\*\*/)|\*+)}, $wild;
    my @re    = ();
    my %wcmap = (
      '*'   => '[^/]*?',
      '**'  => '.*?',
      '**/' => '(?:.+?/)?'
    );
    while (@part) {
      push @re, quotemeta( shift @part );
      push @re, $wcmap{ shift @part } // die if @part;
    }
    push @all, "(?:^" . join( "", @re ) . "\$)";
  }
  return qr{@{[join "|", @all]}};
}

sub match {
  my ( $self, @name ) = @_;
  my $re = $self->_re;
  my @got = grep { /$re/ } @name;
  return @got;
}

no Moose;
__PACKAGE__->meta->make_immutable;

# vim:ts=2:sw=2:sts=2:et:ft=perl
