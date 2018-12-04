#!perl6
use Test;

#4 @ 212,725: 28x25
grammar Claim {
	token TOP    { '#' <id> ' @ ' <coords> ': ' <size> }
	token id     { \d+ }
	token coords { <x> ',' <y> }
	token size   { <x> 'x' <y> }
	token x      { \d+ }
	token y      { \d+ }
	
}

my @claims = '03-input'.IO.lines.map({ Claim.parse($_) });
#@claims.say;

my @fabric;
my %overlaps;

for @claims -> $claim {
	my $start_x = $claim<coords><x>;
	my $start_y = $claim<coords><y>;
	my $end_x =   $claim<size><x> + $start_x - 1;
	my $end_y =   $claim<size><y> + $start_y - 1;

	%overlaps{ $claim<id> } ||= 0;
	
	for $start_x .. $end_x -> $x {
		for $start_y .. $end_y -> $y {
			if @fabric[$y;$x] {
				%overlaps{ @fabric[$y;$x] } = 1;
				%overlaps{ $claim<id> }     = 1;
				@fabric[$y;$x] = 'X';
			}
			else {
				@fabric[$y;$x] = $claim<id>;
			}
		}
	}
}

# I still have no idea how to properly unpack perl6 nested objects
is @fabric.map({.flat}).flat.grep('X').elems, 107043,
	"Found the overlapping claims on the fabric";

is %overlaps.grep({ .value == 0 }).hash.keys, (346),
	"Only one non-overlapping claim";

done-testing;
