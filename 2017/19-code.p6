#!perl6
use Test;

# --- Day 19: A Series of Tubes ---
#
# Somehow, a network packet got lost and ended up here. It's trying to follow a
# routing diagram (your puzzle input), but it's confused about where to go.
#
# Its starting point is just off the top of the diagram. Lines (drawn with |,
# -, and +) show the path it needs to take, starting by going down onto the
# only line connected to the top of the diagram. It needs to follow this path
# until it reaches the end (located somewhere within the diagram) and stop
# there.
#
# Sometimes, the lines cross over each other; in these cases, it needs to
# continue going the same direction, and only turn left or right when there's
# no other option. In addition, someone has left letters on the line; these
# also don't change its direction, but it can use them to keep track of where
# it's been.

class Subway {
    subset Point of List where { .elems == 2 && .all ~~ Int };

    # In order of preference to try them
    my Point @directions = (
        (  0,  1 ), # down
        (  1,  0 ), # right
        (  0, -1 ), # up
        ( -1,  0 ), # left
    );

    has @!map;
    has Point $!coord;
    has Int $!direction is default(0); # index into @directions

    has Str @.path where /^<[A..Z]>$/;
    has Int $.steps = 0;

    submethod BUILD(:@!map) {}

    method find-start() {
        for 0..@!map.end -> $y {
            for 0..@!map[$y].end -> $x {
                return ( $x, $y ) if @!map[$y][$x] eq '|';
            }
        }
    }

    method at-point(Point $p) {
        return if $p.any < 0;
        return @!map[ $p[1] ][ $p[0] ];
    }

    method coord-in(Point $d) { ( $!coord[0] + $d[0], $!coord[1] + $d[1] ) }

    method next-direction() {
        my $current = self.at-point( $!coord );
        die "Unable to move from nowhere" unless $current.defined;

        my @d = $!direction;
        @d.append( ( -1, 1 ).map(( $!direction + * ) % @directions.elems ) )
            if $current eq '+';

        return @d.first({
            if my $coord = self.coord-in( @directions[$_] ) {
                my $a = self.at-point( $coord );
                $a.defined && $a ne ' ';
            }
        });
    }

    method move() {
        unless $!coord {
            $!coord = self.find-start;
            return True;
        }

        my $next = self.next-direction;
        if $next.defined {

            $!coord     = self.coord-in( @directions[$next] );
            $!direction = $next;

            if self.at-point( $!coord ) ~~ /^<[A..Z]>$/ {
                @!path.append( self.at-point($!coord) );
                exit if @!path.elems > 1000;
            }

            return True;
        }
        return False;
    }

    method ride() { $!steps++ while self.move }
}

# For example:
{

    my @map = q:to/EOL/.lines.map(*.comb.cache).cache;
            |
            |  +--+
            A  |  C
        F---|----E|--+
            |  |  |  D
            +B-+  +--+
        EOL

    my $tube = Subway.new(:map(@map));
    $tube.ride;

# Given this diagram, the packet needs to take the following path:
#
#     Starting at the only line touching the top of the diagram, it must go
#     down, pass through A, and continue onward to the first +.
#
#     Travel right, up, and right, passing through B in the process.
#
#     Continue down (collecting C), right, and up (collecting D).
#
#     Finally, go all the way left through E and stopping at F.
#
# Following the path to the end, the letters it sees on its path are ABCDEF.
    is $tube.path.join, 'ABCDEF', "Took the correct path in the tube";
    is $tube.steps, 38, "Took the right number of steps top get there";
}

# The little packet looks up at you, hoping you can help it find the way. What
# letters will it see (in the order it would see them) if it follows the path?
# (The routing diagram is very wide; make sure you view it without line
# wrapping.)
#
# --- Part Two ---
#
# The packet is curious how many steps it needs to go.
#
# For example, using the same routing diagram from the example above...
#
#      |
#      |  +--+
#      A  |  C
#  F---|--|-E---+
#      |  |  |  D
#      +B-+  +--+
#
# ...the packet would go:
#
#     6 steps down (including the first line at the top of the diagram).
#     3 steps right.
#     4 steps up.
#     3 steps right.
#     4 steps down.
#     3 steps right.
#     2 steps up.
#     13 steps left (including the F it stops on).
#
# This would result in a total of 38 steps.
#
# How many steps does the packet need to go?

{
    my @map = "19-input".IO.lines.map(*.comb.cache).cache;
    my $tube = Subway.new(:map(@map));
    $tube.ride;
    is $tube.path.join, 'MKXOIHZNBL', "Rode the long tube";
    is $tube.steps, 17872, "For 17872 steps";
}

done-testing;
