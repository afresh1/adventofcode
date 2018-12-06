#!perl6
use Test;

my $polymer = '05-input'.IO.lines.chomp;

my $match = / [ (<lower>) <{$0.uc}> ] || [ (<upper>) <{$0.lc}> ] /;

{
	my $test = "dabAcCaCBAcCcaDA";
	while $test ~~ s:g/$match// {
		#say $/;
	}
	is $test.chars, 10, "Removed adjacent units with regex";
}

sub process-polymers ($orig) {
	my @string = $orig.comb.map(&ord);

	# Idea to turn into ord and test xor from
	# https://www.reddit.com/r/adventofcode/comments/a3912m/2018_day_5_solutions/eb4qy4f/

	my $i = 0;
	while @string.elems > $i + 1 {
		my ($x, $y) = @string[ $i, $i + 1 ];

		if ( $x +^ $y == 0x20 ) {
			splice @string, $i, 2;
			$i-- if $i > 0;
		}
		else {
			$i++;
		}
	}

	return @string.map(&chr).join;
}

is process-polymers("dabAcCaCBAcCcaDA").chars, 10,
    "Removed adjacent units from test string";

#is process-polymers( $polymer ).chars, 9116,
#    "Processed the full polymer list";

{
	my %sizes = $polymer.comb.map(&lc).sort.squish.map( -> $unit {
		my $size = process-polymers(
		    $polymer.subst(/:i $unit /, '', :g) ).chars;
		diag $unit => $size;
		$unit => $size;
	} );
	is %sizes.min({.value}), ( s => 6890 ),
		"Removing 'sS' has the best result";
}

done-testing;
