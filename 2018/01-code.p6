#!perl6
use Test;

my Int $frequency = 0;
my %seen = ( $frequency => 1 );
my Int $first_seen;

my @changes = '01-input'.IO.lines;

while (! $first_seen.defined) {
	for @changes -> $n {
		$frequency += $n;
		$first_seen = $frequency, last if %seen{$frequency}++;
	}

	once { is $frequency, 536, "Got frequency of initial input" }
}

is $first_seen, 75108, "The frequency we first saw twice";

done-testing;
