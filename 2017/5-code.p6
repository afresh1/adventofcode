#!perl6
use Test;

# --- Day 5: A Maze of Twisty Trampolines, All Alike ---
#
# An urgent interrupt arrives from the CPU: it's trapped in a maze of jump
# instructions, and it would like assistance from any programs with spare
# cycles to help find the exit.
#
# The message includes a list of the offsets for each jump. Jumps are relative:
# -1 moves to the previous instruction, and 2 skips the next one. Start at the
# first instruction in the list. The goal is to follow the jumps until one
# leads outside the list.
#
# In addition, these instructions are a little strange; after each jump, the
# offset of that instruction increases by 1. So, if you come across an offset
# of 3, you would move three instructions forward, but change it to a 4 for the
# next time it is encountered.

sub next-step(Int $i, @list, $two = False --> Int) {
    my $next = @list[$i];
    if   ( $two and $next >= 3 ) { @list[$i]--; }
    else                         { @list[$i]++; }
    $next += $i;
    return -1 unless @list.end >= $next >= 0;
    return $next;
}

# For example, consider the following list of jump offsets:

my @list = < 0 3 0 1 -3 >;

# Positive jumps ("forward") move downward; negative jumps move upward. For
# legibility in this example, these offset values will be written all on one
# line, with the current instruction marked in parentheses. The following steps
# would be taken before an exit is found:


is @list, < 0 3  0  1  -3 >, "before we have taken any steps.";

is next-step(0, @list), 0, "First step says next position is 0";
is @list, < 1 3  0  1  -3  >, "jump with offset 0 (that is, don't jump at all). Fortunately, the instruction is then incremented to 1.";

is next-step( 0, @list), 1, "Second step says next position is 1";
is @list, < 2 3 0  1  -3 >, "step forward because of the instruction we just modified. The first instruction is incremented again, now to 2.";

is next-step( 1, @list ), 4, "Third step says next position is 4";
is @list, < 2  4  0  1 -3 >, "jump all the way to the end; leave a 4 behind.";

is next-step( 4, @list ), 1, "Fourth step puts us back to 1";
is @list, < 2 4 0  1  -2 >, "go back to where we just were; increment -3 to -2.";

is next-step( 1, @list ), -1, "Fifth step puts us out of the maze.";
is @list, < 2  5  0  1  -2 >, "jump 4 steps forward, escaping the maze.";

# In this example, the exit is reached in 5 steps.
#
# How many steps does it take to reach the exit?

{
    my @input = "5-input".IO.lines.map(*.Int);
    my $count = 0;
    my $step = 0;
    while ($step >= 0) {
        $count++;
        $step = next-step($step, @input);
    }
    say "Got out of the maze in $count steps";
}

# --- Part Two ---
#
# Now, the jumps are even stranger: after each jump, if the offset was three or
# more, instead decrease it by 1. Otherwise, increase it by 1 as before.
#
# Using this rule with the above example, the process now takes 10 steps, and
# the offset values after finding the exit are left as 2 3 2 3 -1.

{
    my @list = < 0 3 0 1 -3 >;
    my $count = 0;
    my $step = 0;
    while ($step >= 0) {
        $count++;
        $step = next-step($step, @list, True);
    }
    is $count, 10, "Out of maze two in 10 steps";
    is @list, < 2 3 2 3 -1 >, "With the expected maze state";
}

# How many steps does it now take to reach the exit?

{
    my @input = "5-input".IO.lines.map(*.Int);
    my $count = 0;
    my $step = 0;
    while ($step >= 0) {
        $count++;
        $step = next-step($step, @input, True);
        note "# $count: $step" if $count % 100_000 == 0;
    }
    say "Got out of the maze with second rules in $count steps";
}


done-testing();
