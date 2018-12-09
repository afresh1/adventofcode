#!perl6
use Test;

class Coord {
	has Int $.x;
	has Int $.y;

	method list { return ( $.x, $.y ) }
}

my @labels = flat 'a'..'z', 'A'..'Z';
my &to-coords = { .pairs.map( {
	my ($x, $y) = .value.split(/ ',' \s* /).map({.Int});
	@labels[ .key ] => Coord.new( x => $x, y => $y );
} ) };

# manhattan-distance
sub m-d( $p, $q ) { ( $p.list Z- $q.list ).map(*.abs).sum }
sub furthest-apart(@c) { @c.combinations(2).map({ m-d(|$_) }).max }

my %sample = q:to/EOL/.lines.&to-coords;
1, 1
1, 6
8, 3
3, 4
5, 5
8, 9
EOL

my %input = '06-input'.IO.lines.&to-coords;
#%input.say;

sub compute-distances(%coords) {
	my %distances;

	my $x-range = %coords.values.map({.x}).minmax;
	my $y-range = %coords.values.map({.y}).minmax;

	for $x-range<> X $y-range<> -> $point {
		for %coords.kv -> $id, $coord {
			%distances{$point[0]}{$point[1]}{$id}
			    = m-d( $coord, $point );
		}
	}

	return %distances;
}

#compute-distances(%sample).say;
#compute-distances(%input).say;

sub fill-map(%d) {

	my @rows;
	for %d.keys.sort -> $x {
		my @row;
		for %d{$x}.keys.sort -> $y {
			my %loc = %d{$x}{$y};
			my $min = %loc.values.min || 0;
			my @c = %loc.grep({ .value == $min });
			push @row, @c.elems == 0  ?? ' '
			        !! @c.elems == 1  ?? @c.first.key
			        !!                   '.';	
		}
		push @rows, @row;
	}
	
	return @rows;
}

sub remove-infinite(@m) {
	my %infinite = @m[0, *-1].map({ |$_ }).map({ $_ => True }).Hash;
	for @m -> @row {
		%infinite{ @row[0, *-1] } = True, True;
	}
	%infinite{"."}:delete;
	%infinite{" "}:delete;

	for @m -> @row {
		for @row.kv -> $i, $id {
			@row[$i] = '-' if %infinite{$id};
		}
		
	}
	return @m;
}

sub find-coords-within(%d, $size) {
	my @coords;
	for %d.kv -> $x, %row {
		for %row.kv -> $y, %coords {
			my $score = %coords.values.sum;
			push @coords, $x => $y if $score < $size;
		}
	}
	return @coords;
}


{
	my %distances = compute-distances(%sample);
	my @coords-close-to = find-coords-within(%distances, 32);
	is @coords-close-to.elems, 16, "Found coordinats within 32";

	my @map = fill-map(%distances);
	@map = remove-infinite(@map);
	diag $_ for @map.join("\n");
	my %counts;
	%counts{$_}++ for @map.map({ |$_ }).grep({ %sample{$_}:exists });
	is %counts.max({ .value }).value, 17, "Largest area in sample is 'e'";
}

{
	my %distances = compute-distances(%input);
	my @coords-close-to = find-coords-within(%distances, 10_000);
	is @coords-close-to.elems, 35039, "Found coordinats within 10k";

	my @map = fill-map(%distances);
	@map = remove-infinite(@map);
	#diag $_ for @map.join("\n");
	my %counts;
	%counts{$_}++ for @map.map({ |$_ }).grep({ %input{$_}:exists });
	is %counts.max({ .value }).value, 4143, "Largest area in sample is 'e'";
}

done-testing;
