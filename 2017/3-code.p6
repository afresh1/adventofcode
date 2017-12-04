#!perl6
use Test;

# You come across an experimental new kind of memory stored on an infinite
# two-dimensional grid.
#
# Each square on the grid is allocated in a spiral pattern starting at a
# location marked 1 and then counting up while spiraling outward. For example,
# the first few squares are allocated like this:
#
# 17  16  15  14  13
# 18   5   4   3  12
# 19   6   1   2  11
# 20   7   8   9  10
# 21  22  23---> ...
#
# While this is very space-efficient (no squares are skipped), requested data
# must be carried back to square 1 (the location of the only access port for
# this memory system) by programs that can only move up, down, left, or right.
# They always take the shortest path: the Manhattan Distance between the
# location of the data and square 1.


sub manhattan-distance(Int $n) {
    my $steps  = 0;
    for ( 1, { (.sqrt + 2) ** 2 } ... Inf ) {
        last if $_ == $n;
        if ( $_ > $n ) {
            my $square = $_;
            my $side = $square.sqrt;

            my @corners = ( $square, { $_ -= $side - 1 } ... Inf )[^4];
            @corners.shift while @corners > 1 and @corners[1] > $n;

            my $mid = @corners[0] - abs($side / 2).Int;
            #"Mid: [@corners[0]] $mid [@corners[1]] [$n]".say;

            $steps += abs( $mid - $n );

            #"$n [$steps] [$mid] [$square][$side]".say;
            last;
        }
        $steps++;
    }

    return $steps;
}

# For example:
is(manhattan-distance(1), 0,
    "Data from square 1 is carried 0 steps, since it's at the access port.");
is(manhattan-distance(12), 3,
    "Data from square 12 is carried 3 steps, such as: down, left, left.");
is(manhattan-distance(23), 2,
    "Data from square 23 is carried only 2 steps: up twice.");
is(manhattan-distance(1024), 31,
    "Data from square 1024 must be carried 31 steps.");

say "Manhattan Length of 368078 is " ~ manhattan-distance( 368078 );

done-testing;
