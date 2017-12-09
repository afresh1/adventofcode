#!perl6
use Test;

# --- Day 8: I Heard You Like Registers ---
#
# You receive a signal directly from the CPU. Because of your recent assistance
# with jump instructions, it would like you to compute the result of a series
# of unusual register instructions.
#
# Each instruction consists of several parts: the register to modify, whether
# to increase or decrease that register's value, the amount by which to
# increase or decrease it, and a condition. If the condition fails, skip the
# instruction without modifying the register. The registers all start at 0. The
# instructions look like this:

grammar InstructionLine {
    token TOP { ^
        <register> <.ws> <direction>  <.ws> <value>
        <.ws> <condition>?
    $ }

    rule  condition   { 'if' <.ws> <register> <.ws> <comparison> <.ws> <value> }

    token register   { <[a..z]>+ }
    token value      { '-'? \d+ }
    token comparison { '!=' | <[\<\>\=]> '='? }
    token direction  {  'inc' | 'dec' }
}

subset Register of Str where /^<[a..z]>+/;
subset Operator of Str where /^[ '!=' | <[\<\>\=]> '='? ]$/;

class Condition {
    has Register $!register;
    has Operator $!operator;
    has Int      $!value;

    multi method new(Match $m) {
        self.bless(
            :register($m<register>.Str),
            :operator($m<comparison>.Str),
            :value($m<value>.Int),
        );
    }

    submethod BUILD(:$!register, :$!operator, :$!value) {}

    method check($cpu) {
        my $have = $cpu.get($!register);
        given $!operator {
            when '!='  { $have !=  $!value }
            when  '='  { $have  == $!value }
            when  '==' { $have  == $!value }
            when  '<'  { $have  <  $!value }
            when  '<=' { $have  <= $!value }
            when  '>'  { $have  >  $!value }
            when  '>=' { $have  >= $!value }
            default { die "Unknown operator $!operator" }
        }
    }

    method gist { "if $!register $!operator $!value" }
}

class Instruction {
    has Register  $!register  is required;
    has Int       $!value     is required;
    has Condition $!condition;

    multi method new(Str $s) { self.new( InstructionLine.parse($s) ) }
    multi method new(Match $m) {
        my $value = $m<value>.Int;
        $value = -$value if $m<direction> eq 'dec';

        return self.bless(
            :register($m<register>.Str),
            :value( $value ),
            :condition( $m<condition> ),
        );
    }

    submethod BUILD(:$!register, :$!value, :$condition) {
        if ($condition) {
            $!condition := $condition.isa(Condition)
                ?? $condition
                !! Condition.new($condition);
        }
    }

    method process($cpu) {
        $cpu.add( $!register, $!value )
            if not $!condition or $!condition.check($cpu);
    }

    method Str  { self.gist }
    method gist {
        join " ",
            "$!register inc $!value",
            $!condition ?? $!condition.gist !! ();
    }
}

class CPU {
    has Int %.registers is default(0);

    method process(Instruction $i) { $i.process(self) }

    method get(Register $r) { %!registers{$r} }
    method set(Register $r, Int $v) { %!registers{$r}  = $v }
    method add(Register $r, Int $v) { %!registers{$r} += $v }

    method gist {%!registers.gist}
}

my @instructions = q{
b inc 5 if a > 1
a inc 1 if b < 5
c dec -10 if a >= 1
c inc -20 if c == 10
}.lines.grep(*.chars).map({ Instruction.new($_) });

is Instruction.new(:register('x'), :value(0)).Str, "x inc 0",
    "Instruction without condition stringifies correctly";

# These instructions would be processed as follows:
{
    my $cpu = CPU.new;

    $cpu.process( @instructions[0] );
    is $cpu.registers, {},
        "Because a starts at 0, it is not greater than 1, "
            ~ "and so b is not modified.";

    $cpu.process( @instructions[1] );
    is $cpu.registers, { a => 1 },
        "a is increased by 1 (to 1) because b is less than 5 (it is 0).";

    $cpu.process( @instructions[2] );
    is $cpu.registers, { a => 1, c => 10 },
        "c is decreased by -10 (to 10) because a is now "
            ~ "greater than or equal to 1 (it is 1).";

    $cpu.process( @instructions[3] );
    is $cpu.registers, { a => 1, c => -10 },
        "c is increased by -20 (to -10) because c is equal to 10.";

   is $cpu.registers.values.max, 1,
        "After this process, the largest value in any register is 1.";
}

# You might also encounter <= (less than or equal to) or != (not equal to).
# However, the CPU doesn't have the bandwidth to tell you what all the
# registers are named, and leaves that to you to determine.
#
# What is the largest value in any register after completing the instructions
# in your puzzle input?

# --- Part Two ---
#
# To be safe, the CPU also needs to know the highest value held in any register
# during this process so that it can decide how much memory to allocate to
# these operations. For example, in the above instructions, the highest value
# ever held was 10 (in register c after the third instruction was evaluated).


{
    my $cpu = CPU.new;
    my $max = 0;
    for ("8-input".IO.lines) {
        $cpu.process( Instruction.new($_) );
        $max = max( $max, $cpu.registers.values.max );
    }
    #$cpu.registers.say;
    is $cpu.registers.values.max, 5102,
        "Max value of all registers after processing is what we expected";
    is $max, 6056,
        "Max value seen during processing is what we expected";

}


done-testing;
