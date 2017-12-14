#!perl6

# --- Day 10: Knot Hash ---
#
# You come across some programs that are trying to implement a software
# emulation of a hash based on knot-tying. The hash these programs are
# implementing isn't very strong, but you decide to help them anyway. You make
# a mental note to remind the Elves later not to invent their own cryptographic
# functions.
#
# This hash function simulates tying a knot in a circle of string with 256
# marks on it. Based on the input to be hashed, the function repeatedly selects
# a span of string, brings the ends together, and gives the span a half-twist
# to reverse the order of the marks within it. After doing this many times, the
# order of the marks is used to build the resulting hash.

#   4--5   pinch   4  5           4   1
#  /    \  5,0,1  / \/ \  twist  / \ / \
# 3      0  -->  3      0  -->  3   X   0
#  \    /         \ /\ /         \ / \ /
#   2--1           2  1           2   5

# To achieve this, begin with a list of numbers from 0 to 255, a current
# position which begins at 0 (the first element in the list), a skip size
# (which starts at 0), and a sequence of lengths (your puzzle input). Then, for
# each length:
#
#     Reverse the order of that length of elements in the list, starting with
#     the element at the current position.  Move the current position forward
#     by that length plus the skip size.  Increase the skip size by one.
#
# The list is circular; if the current position and the length try to reverse
# elements beyond the end of the list, the operation reverses using as many
# extra elements as it needs from the front of the list. If the current
# position moves past the end of the list, it wraps around to the front.
# Lengths larger than the size of the list are invalid.

class Knot is export(:Knot) {
    has Int @!knots;
    has Int @!string is default(0...255);

    submethod BUILD(:@string) {
        @string = 0...255 unless @string.elems;
        @!string = @string;
    }

    method to-skip { @!knots.elems }

    method tie(Int $length) {
        my $index = $length - 1;
        @!string[0..$index] = @!string[0..$index].reverse;
        @!string = @!string.rotate( $length + self.to-skip );
        @!knots.push( $length );
    }

    method value() {
        my $index = [+] @!knots.sum, (0..@!knots.elems - 1).sum;
        $index %= @!string.elems;
        return @!string.rotate(-$index);
    }

    method Str   { self.value.join(' ') }
    method gist  { @!string.join(' ') ~ ": " ~ @!knots.gist }
}

