#!perl6
use Test;

my %counts;

my @input = '02-input'.IO.lines;
for @input -> $s {
	%counts{$_}++ for 
	    $s.comb.classify({$_})
	        .map({.value.elems})
	        .grep({ 2 <= $_ <= 3 })
		.unique;
}

is %counts.values.reduce(&[*]), 6000, "The checksum";

my @matches;
for @input -> $x {
	ID: for @input -> $y {
		my $diff;
		for $y.comb.kv -> $i, $c {
			unless $x.substr-eq($c, $i) {
				next ID if $diff.defined;
				$diff = $i
			}
		}
		if $diff.defined {
			my $z = $x;
			$z.substr-rw($diff, 1) = '';
			push @matches, $z;
		}
	}
}

is @matches.unique, 'pbykrmjmizwhxlqnasfgtycdv', "Found the boxes that match";

done-testing;
