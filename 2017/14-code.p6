#!perl6
use Test;

use lib IO::Path.new($?FILE).parent.add('lib');
use KnottedString;

# --- Day 14: Disk Defragmentation ---

sub disk-grid(Str $hashbase, Int $size=128) {
    (0...$size-1).hyper(:batch(4)).map( -> $i {
        "$hashbase-$i".say;
        :16( KnottedString.new("$hashbase-$i").hashed )
            .fmt("%0" ~ $size ~ "b").comb.list;
    }).list;
}

# Suddenly, a scheduled job activates the system's disk defragmenter. Were the
# situation different, you might sit and watch it for a while, but today, you
# just don't have that kind of time. It's soaking up valuable system resources
# that are needed elsewhere, and so the only option is to help it finish its
# task as soon as possible.
#
# The disk in question consists of a 128x128 grid; each square of the grid is
# either free or used. On this disk, the state of the grid is tracked by the
# bits in a sequence of knot hashes.
#
# A total of 128 knot hashes are calculated, each corresponding to a single row
# in the grid; each hash contains 128 bits which correspond to individual grid
# squares. Each bit of a hash indicates whether that square is free (0) or used
# (1).
#
# The hash inputs are a key string (your puzzle input), a dash, and a number
# from 0 to 127 corresponding to the row. For example, if your key string were
# flqrgnkx, then the first row would be given by the bits of the knot hash of
# flqrgnkx-0, the second row from the bits of the knot hash of flqrgnkx-1, and
# so on until the last row, flqrgnkx-127.
#
# The output of a knot hash is traditionally represented by 32 hexadecimal
# digits; each of these digits correspond to 4 bits, for a total of 4 * 32 =
# 128 bits. To convert to bits, turn each hexadecimal digit to its equivalent
# binary value, high-bit first: 0 becomes 0000, 1 becomes 0001, e becomes 1110,
# f becomes 1111, and so on; a hash that begins with a0c2017... in hexadecimal
# would begin with 10100000110000100000000101110000... in binary.
#
# Continuing this process, the first 8 rows and columns for key flqrgnkx appear
# as follows, using # to denote used squares, and . to denote free ones:
#
# ##.#.#..-->
# .#.#.#.#
# ....#.#.
# #.#.##.#
# .##.#...
# ##..#..#
# .#...#..
# ##.#.##.-->
# |      |
# V      V
#
# In this example, 8108 squares are used across the entire 128x128 grid.
#
# --- Part Two ---

sub make-region(@grid, Int $group, Int $start_y, Int $start_x) {
    my $width  = @grid.map(*.end).max;
    my $height = @grid.end;

    my $found = False;

    my @coords = ( $start_y => $start_x );
    while @coords {
        $_ = @coords.shift;
        next unless @grid[ .key ][ .value ] eq '#';

        my $y = .key;
        my $x = .value;

        $found = True;
        @grid[$y][$x] = $group;

        @coords.append( |(-1..1).map( -> $i { (-1..1).map({ $i => $_ }) }).flat
                .grep({ .key == 0 ^^ .value == 0 }) # not diaganals or current
                .map({ .key + $y => .value + $x })
                .grep({ ( 0 <= .key <= $height ) && (0 <= .value <= $width ) })
                .grep({ @grid[.key] && @grid[.key][.value] }).list
        );
    }

    return $found;
}

sub count-regions(@source-grid) {
    my @grid = @source-grid.map(*.map({ $_ == 1 ?? '#' !! '.' }).Array).list;

    my $width  = @grid.map(*.end).max;
    my $height = @grid.end;

    [ $width, $height, @grid.map(*.end).min ].say;

    my $group = 0;
    for 0..$height -> $y {
        next unless @grid[$y];
        for 0..$width -> $x {
            next unless @grid[$y][$x];
            if @grid[$y][$x] eq '#' {
                $group++;
                #say "Group: $group";
                make-region(@grid, $group, $y, $x);
            }
        }
    }

    #say @grid.map({ $_ eq '.' ?? '....' !! .fmt("%4s").join(" ") }).join("\n");

    return $group;
}

# Now, all the defragmenter needs to know is the number of regions. A region is
# a group of used squares that are all adjacent, not including diagonals. Every
# used square is in exactly one region: lone used squares form their own
# isolated regions, while several adjacent squares all count as a single
# region.
#
# In the example above, the following nine regions are visible, each marked
# with a distinct digit:
#
# 11.2.3..-->
# .1.2.3.4
# ....5.6.
# 7.8.55.9
# .88.5...
# 88..5..8
# .8...8..
# 88.8.88.-->
# |      |
# V      V
#
# Of particular interest is the region marked 8; while it does not appear
# contiguous in this small view, all of the squares marked 8 are connected when
# considering the whole 128x128 grid. In total, in this example, 1242 regions
# are present.


{
    my $grid = disk-grid('flqrgnkx');
    # $grid.say;
    # $grid.map(*.join(" ")).join("\n").say;
    is $grid.flat.sum, 8108, "Calculated used squares in sample";
    is count-regions($grid),1242, "Calculated regions correctly";
}

count-regions(
    q:to/EOL/.lines.map(*.comb.map({ $_ eq '#' ?? 1 !! 0 }).list)
        ##.#.#..
        .#.#.#.#
        ....#.#.
        #.#.##.#
        .##.#...
        ##..#..#
        .#...#..
        ##.#.##.
        EOL
).say;

# Given your actual key string, how many squares are used?
# How many regions are present given your key string?

{
    my $grid = disk-grid('uugsqrei');
    #$grid.say;
    is $grid.flat.sum, 8194, "Calculated used squares in actual key";
    is count-regions($grid),1141, "Calculated regions correctly";
}

done-testing;

