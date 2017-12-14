#!perl
# https://www.reddit.com/r/adventofcode/comments/7jgyrt/2017_day_13_solutions/dr6fpiq/
use 5.020;
use warnings;
use experimental qw<signatures>;

my %scanner = map { /\d+/g } <>;
say "severity if leaving immediately: ", severity(\%scanner);
my $delay = 0;
0 while defined severity(\%scanner, ++$delay);
say "delay for severity 0: ", $delay;

sub severity($scanner, $delay = 0) {
  my $severity;
  while (my ($depth, $range) = each %$scanner) {
    my $pos = ($depth + $delay) % (($range - 1) * 2);
    $pos = ($range - 1) * 2 - $pos if $pos >= $range;
    $severity += $depth * $range if $pos == 0;
  }
  $severity;
}

