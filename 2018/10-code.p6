#!perl6
use Test;

class Velocity { has Int $.x; has Int $.y; }
class Point {
	has Int $.x;
	has Int $.y;

	method move( Velocity $v ) {
		$!x += $v.x;
		$!y += $v.y;
	}
 }

class Light {
	has Point    $.position;
	has Velocity $.velocity;

	method move() { $.position.move( $.velocity ) }

	method new( Str $line ) {
		my $xy = rx/ '<'
		  \s* $<x> = [ '-'? \d+ ] ','
		  \s* $<y> = [ '-'? \d+ ] \s*
		'>' /;
		$line ~~ /
		    'position=' $<position> = $xy
		    \s+
		    'velocity=' $<velocity> = $xy
		/ || die "Unable to parse $line";

		return self.bless(
		    position => Point.new( 
		        x => $/<position><x>.Int,
		        y => $/<position><y>.Int,
		    ),
		    velocity => Velocity.new(
		        x => $/<velocity><x>.Int,
		        y => $/<velocity><y>.Int,
		    ),
		);
	}

	method Str { ( $.position.x, $.position.y ).join(", ") }
}

# Assume the message shows up when all the points are as close together
# as they get.   This isn't necessarily true, but was the best idea I had.
sub find-message(@lights) {
	my $tries = 25_000; # the first match could be deep
	my $total-tries = 0;

	# Assume the box is no more than the total number of lights tall
	my $min = @lights.elems;

	my %show;
	my $found-try;

	while $tries-- {
		my %lights = lights-to-coords(@lights);

		# I was doing total size, 
		my $size = abs [-] %lights.values
		    .map({ |.keys.map({.Int}) }).minmax.bounds;

		if $total-tries %% 100 {
			diag [ $total-tries, $min, $size ];
		}

		if $size < $min {
			$tries = 1_000; # keep looking
			$min = $size;
			%show = %lights;
			$found-try = $total-tries;
		}

		$total-tries++;
		.move for @lights;
	}

	return ( $found-try, to-show(%show) );
}

sub lights-to-coords(@lights) {
	my %lights;
	for @lights -> $l {
		%lights{ $l.position.x }{ $l.position.y } = True;
	}
	return %lights;
}

sub to-show(%lights) {
	my $x-range = %lights.keys.map({.Int}).minmax;
	my $y-range = %lights.values.map({ |.keys.map({.Int}) }).minmax;

	return $y-range.map( -> $y {
		$x-range.map( -> $x { ;
			%lights{$x}{$y} ?? '#' !! '.'
		} ).join('');
	}).join("\n");
}


my @sample = q:to/EOL/.lines.map({ Light.new($_) });
position=< 9,  1> velocity=< 0,  2>
position=< 7,  0> velocity=<-1,  0>
position=< 3, -2> velocity=<-1,  1>
position=< 6, 10> velocity=<-2, -1>
position=< 2, -4> velocity=< 2,  2>
position=<-6, 10> velocity=< 2, -2>
position=< 1,  8> velocity=< 1, -1>
position=< 1,  7> velocity=< 1,  0>
position=<-3, 11> velocity=< 1, -2>
position=< 7,  6> velocity=<-1, -1>
position=<-2,  3> velocity=< 1,  0>
position=<-4,  3> velocity=< 2,  0>
position=<10, -3> velocity=<-1,  1>
position=< 5, 11> velocity=< 1, -2>
position=< 4,  7> velocity=< 0, -1>
position=< 8, -2> velocity=< 0,  1>
position=<15,  0> velocity=<-2,  0>
position=< 1,  6> velocity=< 1,  0>
position=< 8,  9> velocity=< 0, -1>
position=< 3,  3> velocity=<-1,  1>
position=< 0,  5> velocity=< 0, -1>
position=<-2,  2> velocity=< 2,  0>
position=< 5, -2> velocity=< 1,  2>
position=< 1,  4> velocity=< 2,  1>
position=<-2,  7> velocity=< 2, -2>
position=< 3,  6> velocity=<-1, -1>
position=< 5,  0> velocity=< 1,  0>
position=<-6,  0> velocity=< 2,  0>
position=< 5,  9> velocity=< 1, -2>
position=<14,  7> velocity=<-2,  0>
position=<-3,  6> velocity=< 2, -1>
EOL

#@sample.say;
is find-message(@sample) ~ "\n", (3, q:to/EOL/), "Sample show as expected";
#...#..###
#...#...#.
#...#...#.
#####...#.
#...#...#.
#...#...#.
#...#...#.
#...#..###
EOL

my @input = '10-input'.IO.lines.map({ Light.new( $_ ) });
is find-message(@input) ~ "\n", ( 10136, q:to/EOL/), "Input show as expected";
######..#....#....##....######..#####...######..#....#..#####.
#.......#....#...#..#........#..#....#.......#..#....#..#....#
#.......#....#..#....#.......#..#....#.......#..#....#..#....#
#.......#....#..#....#......#...#....#......#...#....#..#....#
#####...######..#....#.....#....#####......#....######..#####.
#.......#....#..######....#.....#.........#.....#....#..#.....
#.......#....#..#....#...#......#........#......#....#..#.....
#.......#....#..#....#..#.......#.......#.......#....#..#.....
#.......#....#..#....#..#.......#.......#.......#....#..#.....
######..#....#..#....#..######..#.......######..#....#..#.....
EOL

done-testing;
