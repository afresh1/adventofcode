#!perl6
use Test;

# --- Day 25: The Halting Problem ---
#
# Following the twisty passageways deeper and deeper into the CPU, you finally
# reach the core of the computer. Here, in the expansive central chamber, you
# find a grand apparatus that fills the entire room, suspended nanometers above
# your head.
#
# You had always imagined CPUs to be noisy, chaotic places, bustling with
# activity. Instead, the room is quiet, motionless, and dark.
#
# Suddenly, you and the CPU's garbage collector startle each other. "It's not
# often we get many visitors here!", he says. You inquire about the stopped
# machinery.
#
# "It stopped milliseconds ago; not sure why. I'm a garbage collector, not a
# doctor." You ask what the machine is for.
#
# "Programs these days, don't know their origins. That's the Turing machine!
# It's what makes the whole computer work." You try to explain that Turing
# machines are merely models of computation, but he cuts you off. "No, see,
# that's just what they want you to think. Ultimately, inside every CPU,
# there's a Turing machine driving the whole thing! Too bad this one's broken.
# We're doomed!"
#
# You ask how you can help. "Well, unfortunately, the only way to get the
# computer running again would be to create a whole new Turing machine from
# scratch, but there's no way you can-" He notices the look on your face, gives
# you a curious glance, shrugs, and goes back to sweeping the floor.
#
# You find the Turing machine blueprints (your puzzle input) on a tablet in a
# nearby pile of debris. Looking back up at the broken Turing machine above,
# you can start to identify its parts:
#
#     A tape which contains 0 repeated infinitely to the left and right.
#
#     A cursor, which can move left or right along the tape and read or write
#     values at its current position.
#
#     A set of states, each containing rules about what to do based on the
#     current value under the cursor.
#
# Each slot on the tape has two possible values: 0 (the starting value for all
# slots) and 1. Based on whether the cursor is pointing at a 0 or a 1, the
# current state says what value to write at the current position of the cursor,
# whether to move the cursor left or right one slot, and which state to use
# next.
#
# For example, suppose you found the following blueprint:
class TestTuringMachine {

# Begin in state A.  Perform a diagnostic checksum after 6 steps.

    has $.state;

    has Int %!tape is default(0);
    has Int $!cursor;

    submethod BUILD(:$!cursor) { $!state = 'A' }

    method move-left()  { $!cursor-- }
    method move-right() { $!cursor++ }

    method read()        { %!tape{$!cursor} }
    method write(Int $n) { %!tape{$!cursor} = $n }

    method set-state($new) { $!state = $new };

    method checksum { %!tape.values.sum }

    method step() {
        #( 'step', $!state, $!cursor, %!tape ).say;

        given self.state {
            when 'A' {                       # In state A:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('B'); #     - Continue with state B.
                    }
                    when 1 {                 #   If the current value is 1:
                        self.write(0);       #     - Write the value 0.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('B'); #     - Continue with state B.
                    }
                }
            }
            when 'B' {                       # In state B:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('A'); #     - Continue with state A.
                    }
                    when 1 {                 #   If the current value is 1:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('A'); #     - Continue with state A.
                    }
                }
            }
            default { die "Unknown state $_" }
        }
    }

    method Str  {
        my @keys = %!tape.keys.map(*.Int);
        my $min = @keys ?? @keys.min !! $!cursor;
        my $max = @keys ?? @keys.max !! $!cursor;

        $min-- if $min - $max < 4 and $!cursor <= $min;
        while $max - $min < 5 {
            $min--;
            $max++ if $max - $min < 5;
        }

        (
            '...',
            |( $min ... $max ).map({
                $!cursor eq $_ ?? "[%!tape{$_}]" !! " %!tape{$_} ";
            }),
            '...',
        ).join;
    }
    method gist { %!tape.gist };
}

# Running it until the number of steps required to take the listed diagnostic
# checksum would result in the following tape configurations (with the cursor
# marked in square brackets):

{
    my $machine = TestTuringMachine.new(:cursor(5));

    is $machine.Str, "... 0  0  0 [0] 0  0 ...",
        "(before any steps; about to run state A)";
    is $machine.state, 'A', "> Machine starts in state A";

    $machine.step;
    is $machine.Str, "... 0  0  0  1 [0] 0 ...",
        "(after 1 step;     about to run state B)";
    is $machine.state, 'B', "> Step to step B";

    $machine.step;
    is $machine.Str, "... 0  0  0 [1] 1  0 ...",
        "(after 2 steps;    about to run state A)";
    is $machine.state, 'A', "> Step to step A";

    $machine.step;
    is $machine.Str, "... 0  0 [0] 0  1  0 ...",
        "(after 3 steps;    about to run state B)";
    is $machine.state, 'B', "> Step to step B";

    $machine.step;
    is $machine.Str, "... 0 [0] 1  0  1  0 ...",
        "(after 4 steps;    about to run state A)";
    is $machine.state, 'A', "> Step to step A";

    $machine.step;
    is $machine.Str, "... 0  1 [1] 0  1  0 ...",
        "(after 5 steps;    about to run state B)";
    is $machine.state, 'B', "> Step to step B";

    $machine.step;
    is $machine.Str, "... 0  1  1 [0] 1  0 ...",
        "(after 6 steps;    about to run state A)";
    is $machine.state, 'A', "> Step to step A";

# The CPU can confirm that the Turing machine is working by taking a diagnostic
# checksum after a specific number of steps (given in the blueprint). Once the
# specified number of steps have been executed, the Turing machine should
# pause; once it does, count the number of times 1 appears on the tape. In the
# above example, the diagnostic checksum is 3.
    is $machine.checksum, 3, "Test Checksum is 3";
}
#
# Recreate the Turing machine and save the computer! What is the diagnostic
# checksum it produces once it's working again?

class TuringMachine is TestTuringMachine {

    method step() {
# Begin in state A.
# Perform a diagnostic checksum after 12399302 steps.

        given self.state {
            when 'A' {                       # In state A:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('B'); #     - Continue with state B.
                    }
                    when 1 {                 #   If the current value is 1:
                        self.write(0);       #     - Write the value 0.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('C'); #     - Continue with state C.
                    }
                }
            }
            when 'B' {                       # In state B:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        #self.write(0);       #     - Write the value 0.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('A'); #     - Continue with state A.
                    }
                    when 1 {                 #   If the current value is 1:
                        self.write(0);       #     - Write the value 0.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('D'); #     - Continue with state D.
                    }
                }
            }
            when 'C' {                       # In state C:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('D'); #     - Continue with state D.
                    }
                    when 1 {                 #   If the current value is 1:
                        #self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('A'); #     - Continue with state A.
                    }
                }
            }
            when 'D' {                       # In state D:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('E'); #     - Continue with state E.
                    }
                    when 1 {                 #   If the current value is 1:
                        self.write(0);       #     - Write the value 0.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('D'); #     - Continue with state D.
                    }
                }
            }
            when 'E' {                       # In state E:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('F'); #     - Continue with state F.
                    }
                    when 1 {                 #   If the current value is 1:
                        #self.write(1);       #     - Write the value 1.
                        self.move-left;      #     - Move one slot to the left.
                        self.set-state('B')  #     - Continue with state B.
                    }
                }
            }
            when 'F' {                       # In state F:
                given self.read {
                    when 0 {                 #   If the current value is 0:
                        self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('A'); #     - Continue with state A.
                    }
                    when 1 {                 #   If the current value is 1:
                        #self.write(1);       #     - Write the value 1.
                        self.move-right;     #     - Move one slot to the right.
                        self.set-state('E'); #     - Continue with state E.
                    }
                }
            }
        }
    }
}

if False
{
    # Perform a diagnostic checksum after 12399302 steps.
    my $steps = 12_399_302;
    my $machine = TuringMachine.new(:cursor($steps));
    for 1...$steps {
        $machine.step;
        $_.say if $_ % 100_000 == 0;
        #$machine.Str.say if $_ % 100_000 == 0;
    }
    is $machine.checksum, 2794, "Input Checksum is 2794";
}

sub read-state($input) {
    my %m; # machine

    my $beginning-state;
    my $steps;
    my $s;
    my $v;
    for $input.lines {
        when /'Begin in state ' (<[A..Z]>)/  { $beginning-state = $/[0].Str }
        when /'checksum after ' (\d+)/       { $steps = $/[0].Int }
        when /'In state ' (<[A..Z]>)/        { $s = $/[0].Str }
        when /'current value is ' (<[01]>):/ { $v = $/[0].Int }
        when /'Write the value ' (<[01]>)/   { %m{$s}[$v]<write> = $/[0].Int }
        when /'to the ' (left|right)/        { %m{$s}[$v]<move>  = $/[0].Str }
        when /'with state ' (<[A..Z]>)/      { %m{$s}[$v]<state> = $/[0].Str }
        #default { "FAIL $_".say }
    }
    return { state => $beginning-state, steps => $steps, machine => %m };
}

sub process( :$machine, :$state, :$steps ) {
	my $s = $state;
	my $c = $steps;
	my %t is default(0);

	for 1 .. $steps {
		$_.say if $_ % 100_000 == 0;
		my %action = $machine{$s}[ %t{$c} ];

		%t{$c} = %action<write>;
		given %action<move> {
			when 'left'  { $c-- }
			when 'right' { $c++ }
			default { die "Unknown direction $_" }
		}
		$s = %action<state>;
	}

	return %t;
}

{
    my %input = read-state( q:to/EOL/ );
		Begin in state A.
		Perform a diagnostic checksum after 6 steps.

		In state A:
		If the current value is 0:
			- Write the value 1.
			- Move one slot to the right.
			- Continue with state B.
		If the current value is 1:
			- Write the value 0.
			- Move one slot to the left.
			- Continue with state B.

		In state B:
		If the current value is 0:
			- Write the value 1.
			- Move one slot to the left.
			- Continue with state A.
		If the current value is 1:
			- Write the value 1.
			- Move one slot to the right.
			- Continue with state A.
		EOL

	is process(|%input).values.sum, 3, "Processing test is checksum 3";
}

{
	my %input = read-state( "25-input".IO.slurp );
	is process(|%input).values.sum, 2794, "Processing input is checksum 2794";
}

done-testing;
