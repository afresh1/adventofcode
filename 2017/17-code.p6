#!perl6
use Test;

# --- Day 17: Spinlock ---
#
# Suddenly, whirling in the distance, you notice what looks like a massive,
# pixelated hurricane: a deadly spinlock. This spinlock isn't just consuming
# computing power, but memory, too; vast, digital mountains are being ripped
# from the ground and consumed by the vortex.
#
# If you don't move quickly, fixing that printer will be the least of your
# problems.
#
# This spinlock's algorithm is simple but efficient, quickly consuming
# everything in its path. It starts with a circular buffer containing only the
# value 0, which it marks as the current position. It then steps forward
# through the circular buffer some number of steps (your puzzle input) before
# inserting the first new value, 1, after the value it stopped on. The inserted
# value becomes the current position. Then, it steps forward from there the
# same number of steps, and wherever it stops, inserts after it the second new
# value, 2, and uses that as the new current position again.
#
# It repeats this process of stepping forward, inserting a new value, and using
# the location of the inserted value as the new current position a total of
# 2017 times, inserting 2017 as its final operation, and ending with a total of
# 2018 values (including 0) in the circular buffer.

class SpinLock {
    has Int @!buffer = 0;
    has Int $!i      = 0;
    has Int $!n      = 0;
    has Int $!step;

    submethod BUILD(:$!step) {}

    method spin() {
        $!n++;
        $!i = 1 + ($!step + $!i) % @!buffer.elems;
        "$!i: $!n".say if $!n % 100_000 == 0;
        @!buffer.splice( $!i, 0, $!n );
    }

    method current-step() { $!n }
    method buffer-after( Int $v = $!n ) {
        my $i = @!buffer.first( * == $v, :k ) + 1;
        @!buffer[ $i % @!buffer.elems ];
    }

    method Str()  {
        @!buffer.kv.map( { $^a == $!i ?? "($^b)" !! $^b } ).join(" ");
    }
    method gist() { @!buffer.gist }
}

# For example, if the spinlock were to step 3 times per insert, the circular
# buffer would begin to evolve like this (using parentheses to mark the current
# position after each iteration of the algorithm):

{
    my $spin-lock = SpinLock.new(:step(3));

    is $spin-lock, < (0) >,
        "(0), the initial state before any insertions.";

    $spin-lock.spin;
    is $spin-lock, < 0 (1) >,
        "0 (1): the spinlock steps forward three times (0, 0, 0),
        and then inserts the first value, 1, after it.
        1 becomes the current position.";

    $spin-lock.spin;
    is $spin-lock, < 0 (2) 1 >,
        "0 (2) 1: the spinlock steps forward three times (0, 1, 0),
        and then inserts the second value, 2, after it.
        2 becomes the current position.";

    $spin-lock.spin;
    is $spin-lock, < 0 2 (3) 1 >,
        "0  2 (3) 1: the spinlock steps forward three times (1, 0, 2),
        and then inserts the third value, 3, after it.
        3 becomes the current position.";

# And so on:
for (
    #< 0 2 (3) 1 >,
    < 0  2 (4) 3  1 >,
    < 0 (5) 2  4  3  1 >,
    < 0  5  2  4  3 (6) 1 >,
    < 0  5 (7) 2  4  3  6  1 >,
    < 0  5  7  2  4  3 (8) 6  1 >,
    < 0 (9) 5  7  2  4  3  8  6  1 >,
) {
    $spin-lock.spin;
    is $spin-lock, $_, "Next step $_";
}

# Eventually, after 2017 insertions, the section of the circular buffer near
# the last insertion looks like this:
    $spin-lock.spin while $spin-lock.current-step < 2017;

    like $spin-lock.Str, /' 1512 1134 151 (2017) 638 1513 851 '/,
        "Around last insert looks like  1512  1134  151 (2017) 638  1513  851";

# Perhaps, if you can identify the value that will ultimately be after the last
# value written (2017), you can short-circuit the spinlock. In this example,
# that would be 638.
    is $spin-lock.buffer-after, 638,
        "Next value after 2017 is 638";
}

# What is the value after 2017 in your completed circular buffer?
#
# Your puzzle input is 329.
{
    my $spin-lock = SpinLock.new(:step(329));
    $spin-lock.spin while $spin-lock.current-step < 2017;
    is $spin-lock.buffer-after, 725, "Next buffer with a 329 step is 725";

# --- Part Two ---
#
# The spinlock does not short-circuit. Instead, it gets more angry. At least,
# you assume that's what happened; it's spinning significantly faster than it
# was a moment ago.
#
# You have good news and bad news.
#
# The good news is that you have improved calculations for how to stop the
# spinlock. They indicate that you actually need to identify the value after 0
# in the current state of the circular buffer.
#
# The bad news is that while you were determining this, the spinlock has just
# finished inserting its fifty millionth value (50000000).
#
# What is the value after 0 the moment 50000000 is inserted?

    # Actually putting things into the array is too slow,
    # especially on perl6.
    #$spin-lock.spin while $spin-lock.current-step < 50_000_000;
    #is $spin-lock.buffer-after(0), 0,
    #    "After 50 million steps, the buffer after value 0 is ?";
}

# I didn't even try to think of this solution, instead was browsing
# the reddit forum and saw it while the brute-force was running.
{
    my $i = 0;
    my $after-zero = 0;
    # for 1 ... 50_000_000 -> $t { # uses much memory :-(
    my $t = 0; while $t++ <= 50_000_000 {
        $i = ( $i + 329 ) % $t + 1;
        $after-zero = $t if $i == 1;
        "# [$t.fmt("%8d")] $after-zero.fmt("%8d") ($i.fmt("%8d"))".say
            if $t % 100_000 == 0;
    }
    is $after-zero, 27361412, "The number after zero at 50 million.";
}

done-testing;
