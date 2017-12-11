#!perl6
use Test;

# --- Day 11: Hex Ed ---
#
# Crossing the bridge, you've barely reached the other side of the stream when
# a program comes up to you, clearly in distress. "It's my child process," she
# says, "he's gotten lost in an infinite grid!"
#
# Fortunately for her, you have plenty of experience with infinite grids.
#
# Unfortunately for you, it's a hex grid.
#
# The hexagons ("hexes") in this grid are aligned such that adjacent hexes can
# be found to the north, northeast, southeast, south, southwest, and northwest:
#
#   \ n  /
# nw +--+ ne
#   /    \
# -+      +-
#   \    /
# sw +--+ se
#   / s  \

subset HexGridPoint of Rat where * % 0.5 == 0;

class InfiniteHexGrid {
    has HexGridPoint $!x;
    has HexGridPoint $!y;

    my %bearings = (
        '' => [],

        n => [  0.0,  1.0 ],
        e => [  1.0,  0.0 ],
        w => [ -1.0,  0.0 ],
        s => [  0.0, -1.0 ],

        ne => [  0.5,  0.5 ],
        nw => [ -0.5,  0.5 ],
        se => [  0.5, -0.5 ],
        sw => [ -0.5, -0.5 ],
    );

    subset Bearing of Str where { %bearings{$_}:exists };

    submethod BUILD { $!x = 0.0; $!y = 0.0 }

    multi method move(Bearing $bearing)  {
        my ($x, $y) = %bearings{$bearing};
        $!x += $x;
        $!y += $y;
    }
    multi method move(@bearings)  { self.move($_) for @bearings }

    method bearing-to-zero() returns Bearing { self.bearing-to( 0.0, 0.0 ) }
    method bearing-to(Rat $x, Rat $y) returns Bearing {
        my $bearing = '';

        given $!y {
            when $_ > $y { $bearing ~= 's' }
            when $_ < $y { $bearing ~= 'n' }
        }

        given $!x {
            when $_ > $x { $bearing ~= 'w' }
            when $_ < $x { $bearing ~= 'e' }
        }

        return $bearing;
    }

    #method return-to-zero() returns List where { $_.all ~~ Bearing } {
    method return-to-zero() { self.move-to( 0.0, 0.0 ) }
    method move-to(Rat $x, Rat $y) {
        my @trip;
        while ( my $bearing = self.bearing-to( $x, $y ) ) {
            @trip.push: $bearing;
            self.move: $bearing;
        }
        return @trip;
    }

    method steps-to-zero() { self.steps-to( 0.0, 0.0 ) }
    method steps-to(Rat $x, Rat $y) {
        my @save = $!x, $!y;
        my @trip = self.move-to( $x, $y );
        ($!x, $!y) = @save;
        return @trip;
    }

    method distance-to-zero() { self.distance-to( 0.0, 0.0 ) }
    method distance-to(Rat $x, Rat $y) {
        my ($min, $max) = ( $!x - $x, $!y - $y ).map(*.abs).sort;
        return ( (2 * $min) + $max - $min );
    }

    method Str()  { self.gist.join(', ') }
    method gist() { $!x, $!y }
}

# You have the path the child process took. Starting where he started, you need
# to determine the fewest number of steps required to reach him. (A "step"
# means to move from the hex you are in to any adjacent hex.)
#
# For example:
{
    my $grid = InfiniteHexGrid.new;
    $grid.move( < ne ne ne > );
    is $grid.gist, [ 1.5, 1.5 ], "Ended up at 1.5, 1.5";
    is $grid.bearing-to-zero, 'sw', "Bearing towards zero is sw";
    is $grid.distance-to-zero, $grid.steps-to-zero.elems,
        "ne,ne,ne is 3 steps away.";
    is $grid.return-to-zero, < sw sw sw >,
        "ne,ne,ne returns via sw,sw,sw.";
}
{
    my $grid = InfiniteHexGrid.new;
    $grid.move( < ne ne sw sw > );
    is $grid.gist, [ 0, 0 ], "Ended up back at zero";
    is $grid.bearing-to-zero, '', "Bearing towards zero is empty";
    is $grid.distance-to-zero, $grid.steps-to-zero.elems,
        "ne,ne,sw,sw is 0 steps away (back where you started).";
    is $grid.return-to-zero, [], "and has no steps";
}
{
    my $grid = InfiniteHexGrid.new;
    $grid.move( < ne ne s s > );
    is $grid.gist, [ 1, -1 ], "We are at 1, -1";
    is $grid.distance-to-zero, $grid.steps-to-zero.elems,
        "ne,ne,ne is 3 steps away.";
    my $return-grid = InfiniteHexGrid.new;
    is InfiniteHexGrid.new.move-to( 1.0, -1.0 ), < se se >,
        "ne,ne,s,s is 2 steps away (se,se).";
}
{
    my $grid = InfiniteHexGrid.new;
    $grid.move( < se sw se sw sw > );
    is $grid.gist, [ -0.5, -2.5 ], "Moved to -0.5, -2.5";
    is $grid.distance-to-zero, $grid.steps-to-zero.elems,
        "se,sw,se,sw,sw is 3 steps away.";
    is InfiniteHexGrid.new.move-to( |$grid.gist ).reverse, < s s sw >,
        "se,sw,se,sw,sw is 3 steps away (s,s,sw).";
}
{
    my $grid = InfiniteHexGrid.new;
    my $max = 0;
    for ("11-input".IO.lines.first.split(',') ) {
        $grid.move($_);
        my ($x, $y) = $grid.gist;
        my $distance = $grid.distance-to-zero;
        $max = $distance if $distance > $max;
    }
    is $grid.gist, [ -219, -577 ], "Moved all the way to -219, -577";
    is $grid.return-to-zero.elems, 796, "Minimum number of steps is 796";

    is $max, 1585, "Got as far as 1585 steps from home";
}

# --- Part Two ---
#
# How many steps away is the furthest he ever got from his starting position?


done-testing;
