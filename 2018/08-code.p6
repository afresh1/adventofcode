#!perl6
use Test;

sub parse-node( @in, $names = ("A".."Z").iterator ) {
	my $nodes = @in.shift;
	my $metas = @in.shift;

	return {
		name     => $names.pull-one,
		children => (0..^$nodes).map({ parse-node(@in, $names) })>><>,
		metadata => (0..^$metas).map({ @in.shift })>><>,
	};
}

sub sum-metadata($node) {
	$node<metadata>.sum + $node<children>.map({ sum-metadata($_) }).sum;
}

sub value-node($node) {
	return $node<metadata>.sum unless $node<children>.elems;

	return $node<metadata>.map(-> $n {
		return 0 if $n == 0;
		my $i = $n - 1;
		
		$node<children>[$i]:exists
		    ?? value-node( $node<children>[$i] )
		    !! 0;
	}).sum;
}

my @sample = q:to/EOL/.comb(/\d+/).map({.Int});
2 3 0 3 10 11 12 1 1 0 1 99 2 1 1 2
EOL

my $sample = parse-node(@sample);
#$sample.perl.say;
is sum-metadata($sample), 138, "Metadata total for sample";
is value-node($sample), 66, "Value of sample";

my @input = '08-input'.IO.comb(/\d+/).map({.Int});
my $input = parse-node(@input);
is sum-metadata($input), 49426, "Metadata total for input";
is value-node($input), 40688, "Value of input";

done-testing;
