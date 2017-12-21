#!/usr/bin/perl
use 5.020;
use warnings;

# https://www.reddit.com/r/adventofcode/comments/7kz6ik/2017_day_20_solutions/drj0au0/

#use List::AllUtils qw<sum>;
sub sum(@) { my $x = 0; $x += $_ for @_; $x }
sub uniq(@) { my %seen; grep { !$seen{$_}++ } @_ }
sub after_incl(&@) {
 	my $s = shift;
 	my $i = -1;
	++$i while ($i <= $#_) && $s->( $_[$i] );
	return if $i > $#_;
	 @_[$i..$#_];
 }

my @input = readline;

my ($lowest_accel, $id_of_lowest_accel);
if (0) {
for (@input) {
  my $accel = sum map { abs } /-?\d+(?!.*a)/g;
  if (!defined $lowest_accel || $accel < $lowest_accel) {
    $lowest_accel = $accel;
    $id_of_lowest_accel = $. - 1;
  }
  elsif ($accel == $lowest_accel) {
    warn "IDs $id_of_lowest_accel and $. both have accel sum of $accel. Write some more code!\n";
  }
}
say $id_of_lowest_accel;
}

my %particle = map {
  state $id = 0;
  my %prop = map { /^(.)/ => [/-?\d+/g] } split;
  $id++ => [map { {p => $_, v => shift @{$prop{v}}, a => shift @{$prop{a}}} } @{$prop{p}}];
} @input;

my $converging;
do {
  $converging = 0;
  my %pos;
  foreach my $id (keys %particle) {
    push @{$pos{join ',', map {
      $_->{p} += $_->{v} += $_->{a};
      $converging ||= !same_sign(after_incl { $_ } @$_{qw<a v p>});
      $_->{p};
    } @{$particle{$id}}}}, $id;
  }
  foreach (values %pos) {
    delete @particle{@$_} if @$_ > 1;
  }
} while $converging;
say "Remaining particles: " . keys %particle;

sub same_sign { (uniq map { $_ < 0 } @_) == 1 }

