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
	my @string = $orig.comb;

	my $i = 0;
	while @string.elems > $i + 1 {
		my ($x, $y) = @string[ $i, $i + 1 ];

		if (
		    $x.uniprop('Lowercase') and $x.uc eq $y
			or
		    $x.uniprop('Uppercase') and $x.lc eq $y
		) {
			splice @string, $i, 2;
			$i-- if $i > 0;
		}
		else {
			$i++;
		}
	}

	return @string.join;
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
