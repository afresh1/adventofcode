#!perl6
use Test;

use lib IO::Path.new($?FILE).parent.add('lib');
use Instructions;
use DuetFixed;

# --- Day 23: Coprocessor Conflagration ---
#
# You decide to head directly to the CPU and fix the printer from there. As you
# get close, you find an experimental coprocessor doing so much work that the
# local programs are afraid it will halt and catch fire. This would cause
# serious issues for the rest of the computer, so you head in and see what you
# can do.
#
# The code it's running seems to be a variant of the kind you saw recently on
# that tablet. The general functionality seems very similar, but some of the
# instructions are different:
#
#     set X Y sets register X to the value of Y.
#
#     sub X Y decreases register X by the value of Y.
#
#     mul X Y sets register X to the result of multiplying the value contained
#     in register X by the value of Y.
#
#     jnz X Y jumps with an offset of the value of Y, but only if the value of
#     X is not zero. (An offset of 2 skips the next instruction, an offset of
#     -1 jumps to the previous instruction, and so on.)
#
#     Only the instructions listed above are used. The eight registers here,
#     named a through h, all start at 0.
#
# The coprocessor is currently set to some kind of debug mode, which allows for
# testing, but prevents it from doing any meaningful work.
#
# If you run the program (your puzzle input), how many times is the mul
# instruction invoked?

class Coprocessor is DuetFixed {
}

{
    my @instructions = parse-instructions("23-input".IO.lines);
    my $proc = Coprocessor.new(:instructions(@instructions));

    my $mul = 0;
    while True {
        my $ret = $proc.process;
        last unless $ret;
        #$ret.say;
        $mul++ if $ret[0] eq 'mul';
    }
    is $mul, 9409, "Processed input instructions";
}

# --- Part Two ---
#
# Now, it's time to fix the problem.
#
# The debug mode switch is wired directly to register a. You flip the switch,
# which makes register a now start at 1 when the program is executed.
#
# Immediately, the coprocessor begins to overheat. Whoever wrote this program
# obviously didn't choose a very efficient implementation. You'll need to
# optimize the program if it has any hope of completing before Santa needs that
# printer working.
#
# The coprocessor's ultimate goal is to determine the final value left in
# register h once the program completes. Technically, if it had that... it
# wouldn't even need to run the program.
#
# After setting register a to 1, if the program were to run to completion, what
# value would be left in register h?

{
	my $b = 109900;
	my $c = 126900;
	my @values = ( $b, { $_ + 17 } ... $c );
	#@values.elems.say;

	# https://www.reddit.com/r/adventofcode/comments/7lms6p/2017_day_23_solutions/drngt60/
	my @non-primes = @values.hyper.grep(!*.is-prime);

#	my @primes     = ( 2 ... ( $c div 2 ) ).hyper.grep(*.is-prime).list;
#	@primes.elems.say;
#
#	my @non-primes = @primes.combinations(1..2).hyper
#		.map({ .head * .tail })
#		.grep({ $b <= $_ <= $c })
#		.grep({ @values (cont) $_ })
#		.kv.map({ ( $^a, $^b ).say; $^b });
#
	is @non-primes.elems, 913, "Found 913 non-pime numbers";
}

if False
{
    my @instructions = parse-instructions("23-input".IO.lines);

    # Add an instruction to stop looking if the product is greater than "b"
    @instructions.splice( 16, 0, {
         instruction => 'jgz', args => ( 'g', 9 ),
    } );

    # Make future loops skip our extra instruction
    for @instructions[17..*]
        .grep(*<instruction> eq 'jnz').grep(*<args>[1] < 0) {
            $_<args> = ( $_<args>[0], $_<args>[1] - 1 );
    }
#@instructions.map(*.say); exit;

    my $proc = Coprocessor.new(:instructions(@instructions));
    $proc.set( 'a', 1 ); # turn off debugging

    my $i;
    while True {
        my $ret = $proc.process;
( $ret, $proc.gist ).say if $proc.get('e') == 2 && $proc.get('g') == 2;
        last unless $ret;
    }
    is $proc, '', "Expected register output";
}

done-testing;
