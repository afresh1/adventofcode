#!perl6
use Test;

my $input = 368078;

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

say "Manhattan Length of $input is " ~ manhattan-distance( $input );

# --- Part Two ---

my @manhattan-rings =  1, { Int(.sqrt + 2) ** 2 } ... Inf;

multi num-to-coord(0) { Nil }
multi num-to-coord(1) { 0 => 0 }
multi num-to-coord(Int $n --> Pair ) {
    my $coord = num-to-coord( $n - 1 );

    my $ring  = @manhattan-rings.first( * >= $n );
    my $side  = $ring.sqrt - 1;

    my $d = 'x';
    my $direction = 1 => 0;

    # The first item in a ring moves a special direction.
    if ($n != $ring - ( ( $side * 4 ) - 1 )) {

        # Direction each side moves ordered biggest $n to smalles:
        #                 bottom,    left,     top,  right
        my @directions  = 1 => 0, 0 => -1, -1 => 0,  0 => 1;
        $direction      = 0;

        while ( $n <= $ring - $side ) {
            $direction++;
            $ring -= $side;
        }

        $d = $direction;
        $direction = @directions[ $direction % @directions.elems ];
    }

    return $coord.key + $direction.key => $coord.value + $direction.value;
}

# 17  16  15  14  13
# 18   5   4   3  12
# 19   6   1   2  11
# 20   7   8   9  10
# 21  22  23---> ...
#
my @expect = (
     Nil,
     0 =>  0, #  1
     1 =>  0, #  2
     1 =>  1, #  3
     0 =>  1, #  4
    -1 =>  1, #  5
    -1 =>  0, #  6
    -1 => -1, #  7
     0 => -1, #  8
     1 => -1, #  9
     2 => -1, # 10
     2 =>  0, # 11
     2 =>  1, # 12
     2 =>  2, # 13
);

for @expect.kv -> $n, $p {
    next unless $n;
    is num-to-coord($n),  $p, "Coords for point $n";
}

for 1..12 -> $n {
    is num-to-coord( @manhattan-rings[$n] ), $n => -$n,
        "Coords for ring $n";
}


my %manhattan = 0 => { 0 => { n => 1, value => 1} };
multi manhattan-value(1) { 1 }
multi manhattan-value(Int $n) {
    my $value = manhattan-value( $n - 1 );
    my $coord = num-to-coord( $n );

    for -1, 0, 1 -> $x {
        for -1, 0, 1 -> $y {
            next if $x == 0 && $y == 0;
            next unless %manhattan{ $coord.key + $x }
                    and %manhattan{ $coord.key + $x }{ $coord.value + $y };

            my %other = %manhattan{ $coord.key + $x }{ $coord.value + $y };
            next if %other<n> >= $n - 1; # already added us and us - 1

            $value += %other<value>;
        }
    }

    %manhattan{ $coord.key }{ $coord.value } = { n => $n, value => $value };
    return $value;
}

# As a stress test on the system, the programs here clear the grid and then store the value 1 in square 1. Then, in the same allocation order as shown above, they store the sum of the values in all adjacent squares, including diagonals.
#
# So, the first few squares' values are chosen as follows:

is manhattan-value(1), 1, 
     "Square 1 starts with the value 1.";
is manhattan-value(2), 1,
     "Square 2 has only one adjacent filled square (with value 1), so it also stores 1.";
is manhattan-value(3), 2,
     "Square 3 has both of the above squares as neighbors and stores the sum of their values, 2.";
is manhattan-value(4), 4,
     "Square 4 has all three of the aforementioned squares as neighbors and stores the sum of their values, 4.";
is manhattan-value(5), 5,
     "Square 5 only has the first and fourth squares as neighbors, so it gets the value 5.";

# Once a square is written, its value does not change. Therefore, the first few squares would receive the following values:
#
# 147  142  133  122   59
# 304    5    4    2   57
# 330   10    1    1   54
# 351   11   23   25   26
# 362  747  806--->   ...
#
# What is the first value written that is larger than your puzzle input?

for 1..Inf -> $n {
    my $value = manhattan-value( $n );
    if ( $value > $input) {
        say "Manhattan value $value at square $n is greater than $input";
        last;
    }
}

done-testing;
