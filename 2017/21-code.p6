#!perl6
use Test;

# --- Day 21: Fractal Art ---
#
# You find a program trying to generate some art. It uses a strange process
# that involves repeatedly enhancing the detail of an image through a set of
# rules.
#
# The image consists of a two-dimensional square grid of pixels that are either
# on (#) or off (.). The program always begins with this pattern:
class Universe {
    has %!rules;
    has @!image; # where { .all ~~ ( '.' || '#' ) };

    submethod BUILD(:%!rules) { @!image = (
        < . # . >,
        < . . # >,
        < # # # >
    ) }
# .#.
# ..#
# ###
#
# Because the pattern is both 3 pixels wide and 3 pixels tall, it is said to
# have a size of 3.
#
# Then, the program repeats the following process:
    method process() {
        my $block-size = self.block-size;
        my @corners    = self.block-corners($block-size);
        my @blocks     = @corners.hyper
            .map({ self.enhance( $_, $block-size ) });

        my @new;
        for @blocks.kv -> $k, @block {
            my $i = @corners[$k].value / $block-size * @block.elems;
            for @block.kv -> $j, @row {
                @new[ $i + $j ].append( @row );
            }
        }
        @!image = @new;
    }

    method block-size() returns Int {
        return $_ if @!image.elems % $_ == 0 for 2..3;
        die "Strange block size @!image.elems";
    }

    method block-corners(Int $block-size) {
        ( 0, $block-size ... @!image.end ).map( -> $x {
            ( 0, $block-size ... @!image.end ).map( -> $y { $x => $y })
        } ).flat;
    }

#     If the size is evenly divisible by 2, break the pixels up into 2x2
#     squares, and convert each 2x2 square into a 3x3 square by following the
#     corresponding enhancement rule.
#
#     Otherwise, the size is evenly divisible by 3; break the pixels up into
#     3x3 squares, and convert each 3x3 square into a 4x4 square by following
#     the corresponding enhancement rule.
#
# Because each square of pixels is replaced by a larger one, the image gains
# pixels and so its size increases.

    method enhance( $corner, $block-size ) {
        my @block = @!image[ $corner.value .. $corner.value + $block-size - 1 ]
            .map({ $_[ $corner.key .. $corner.key + $block-size - 1 ] });

        return %!rules{ format-puzzle( @block ) }
            || die "Unable to map " ~ @block.gist ~ " to a rule";
    }

    method Str  { @!image.map(*.join).join("\n") }
    method gist { @!image.gist }
}

# The artist's book of enhancement rules is nearby (your puzzle input);
# however, it seems to be missing rules. The artist explains that sometimes,
# one must rotate or flip the input pattern to find a match. (Never rotate or
# flip the output pattern, though.) Each pattern is written concisely: rows are
# listed as single units, ordered top-down, and separated by slashes. For
# example, the following rules correspond to the adjacent patterns:
grammar Rules {
    token TOP { <entry>* { make $<entry>.map(*.made).flat } }

    rule entry { <pattern> '=>' <pattern>
        { make $<pattern>.map(*.made).pairup }
    }
    rule pattern { <row> [ '/' <row> ]* { make $<row>.map(*.made).list } }

    token row   { <pixel>+ { make $<pixel>.map(*.made).list } }
    token pixel { <[\.#]>  { make $/.Str } }
}

sub read-rules(Str $input) {
    my %rules;
    for Rules.parse($input).made -> $r {
        %rules{ format-puzzle( $r.key ) } = $r.value;

        for False, True -> $flip {
            my @working = $flip ?? $r.key.map(*.reverse.list) !! $r.key;
            for 0, 1, 2, 3 -> $rotate {
                if $rotate {
                    @working = rotate-block(@working) for 1..$rotate;
                }
                %rules{ format-puzzle(@working) } = $r.value;
            }
        }
    }
    return %rules;
}

sub format-puzzle(@puzzle) { @puzzle.map(*.join).join("\n") }
sub say-puzzle(@puzzle)    { format-puzzle(@puzzle).say }

# https://en.wikipedia.org/wiki/In-place_matrix_transposition#Square_matrices
sub rotate-block(@block) {
    my @new = @block.map(*.Array).list;
    for 0 .. @new.elems - 2 -> $n {
        for $n + 1 .. @new.elems - 1 -> $m {
            ( @new[$m][$n], @new[$n][$m] ) = ( @new[$n][$m], @new[$m][$n] );
        }
    }
    return @new.map(*.list).reverse;
}

# ../.#  =  ..
#           .#
#
#                 .#.
# .#./..#/###  =  ..#
#                 ###
#
#                         #..#
# #..#/..../#..#/.##.  =  ....
#                         #..#
#                         .##.
#
# When searching for a rule to use, rotate and flip the pattern as necessary.
# For example, all of the following patterns match the same rule:
#
# .#.   .#.   #..   ###
# ..#   #..   #.#   ..#
# ###   ###   ##.   .#.
#
# Suppose the book contained the following two rules:
my %test-rules = read-rules(q:to/EOL/);
    ../.# => ##./#../...
    .#./..#/### => #..#/..../..../#..#
    EOL

#    is %test-rules, [
#        (< . . >,
#         < . # >
#        ) =>
#        (< # # . >,
#         < # . . >,
#         < . . . >
#        ),
#        ( < . # . >,
#          < . . # >,
#          < # # # >,
#        ) =>
#        (< # . . # >,
#         < . . . . >,
#         < . . . . >,
#         < # . . # > ),
#    ], "Test rules parsed correctly";

{
# As before, the program begins with this pattern:
    my $universe = Universe.new(:rules(%test-rules));
    is $universe ~ "\n", q:to/EOL/, "Universe starts in order";
        .#.
        ..#
        ###
        EOL

# The size of the grid (3) is not divisible by 2, but it is divisible by 3. It
# divides evenly into a single square; the square matches the second rule,
# which produces:

    $universe.process;
    is $universe ~ "\n", q:to/EOL/, "Step one expands the universe";
        #..#
        ....
        ....
        #..#
        EOL

# The size of this enhanced grid (4) is evenly divisible by 2, so that rule is
# used. It divides evenly into four squares:
#
# #.|.#
# ..|..
# --+--
# ..|..
# #.|.#
#
# Each of these squares matches the same rule (../.# => ##./#../...), three of
# which require some flipping and rotation to line up with the rule. The output
# for the rule is the same in all four cases:
#
# ##.|##.
# #..|#..
# ...|...
# ---+---
# ##.|##.
# #..|#..
# ...|...
#
# Finally, the squares are joined into a new grid:

    $universe.process;
    is $universe ~ "\n", q:to/EOL/, "Step two expands the universe";
        ##.##.
        #..#..
        ......
        ##.##.
        #..#..
        ......
        EOL

# Thus, after 2 iterations, the grid contains 12 pixels that are on.
    is $universe.gist.comb('#').elems, 12, "12 on pixels";
}

# How many pixels stay on after 5 iterations?
{
    my %input-rules = read-rules("21-input".IO.slurp);
    my $universe = Universe.new(:rules(%input-rules));
    $universe.process for 1..5;
    is $universe.gist.comb('#').elems, 136, "136 on pixels on input";
    for 6..18 -> $n {
        $universe.process;
        ( "# $n: " ~ $universe.gist.comb('#').elems ).say;
    }
    is $universe.gist.comb('#').elems, 1911767,
        "1911767 on pixels after 18 rounds";
}

done-testing;
