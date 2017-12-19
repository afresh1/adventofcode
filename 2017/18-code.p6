#!perl6
use Test;

# --- Day 18: Duet ---
#
# You discover a tablet containing some strange assembly code labeled simply
# "Duet". Rather than bother the sound card with it, you decide to run the code
# yourself. Unfortunately, you don't see any documentation, so you're left to
# figure out what the instructions mean on your own.
#
# It seems like the assembly is meant to operate on a set of registers that are
# each named with a single letter and that can each hold a single integer. You
# suppose each register should start with a value of 0.
#
# There aren't that many instructions, so it shouldn't be hard to figure out
# what they do. Here's what you determine:

grammar InstructionDefinition {
    token TOP { <snd> | <set> | <add> | <mul> | <mod> | <rcv> | <jgz>  }

#     snd X plays a sound with a frequency equal to the value of X.
    rule snd { 'snd' <value> }

#     set X Y sets register X to the value of Y.
    rule set { 'set' <register> <value> }

#     add X Y increases register X by the value of Y.
    rule add { 'add' <register> <value> }

#     mul X Y sets register X to the result of multiplying the value contained
#     in register X by the value of Y.
    rule mul { 'mul' <register> <value> }

#     mod X Y sets register X to the remainder of dividing the value contained
#     in register X by the value of Y (that is, it sets X to the result of X
#     modulo Y).
    rule mod { 'mod' <register> <value> }

#     rcv X recovers the frequency of the last sound played, but only when the
#     value of X is not zero. (If it is zero, the command does nothing.)
    rule rcv { 'rcv' <value> }

#     jgz X Y jumps with an offset of the value of Y, but only if the value of
#     X is greater than zero. (An offset of 2 skips the next instruction, an
#     offset of -1 jumps to the previous instruction, and so on.)
    rule jgz { 'jgz' <value> <value> }

# Many of the instructions can take either a register (a single letter) or a
# number. The value of a register is the integer it contains; the value of a
# number is that number.

    token value { <register> | <integer> }
    token register { <[a..z]> }
    token integer  { '-'? \d+ }
}

class Instructions {
    method TOP($/) {
        my $i = $/.hash.first;
        make { instruction => $i.key, args => $i.value.made }
    }

    method snd($/) { make ( $<value>.made ) }
    method set($/) { make ( $<register>.made, $<value>.made ) }
    method add($/) { make ( $<register>.made, $<value>.made ) }
    method mul($/) { make ( $<register>.made, $<value>.made ) }
    method mod($/) { make ( $<register>.made, $<value>.made ) }
    method rcv($/) { make ( $<value>.made ) }
    method jgz($/) { make $<value>.map(*.made) }

    method value($/)   {
        make $/<register> ?? $/<register>.made !! $/<integer>.made
    }
    method register($/) { make $/.Str }
    method integer($/)  { make $/.Int }
}

sub parse-instructions(@instructions) {
    my $actions = Instructions.new;
    return @instructions.map({
        InstructionDefinition.parse( $_, :actions( $actions )).made
    });
}

class Duet {
    has Int $.i = 0;
    has @!instructions;

    has Int %!registers is default(0);
    has Int $.sound;

    submethod BUILD(:@!instructions) {}

    multi method snd(Str $v) { self.snd( %!registers{$v} ) }
    multi method snd(Int $v) { $!sound = $v }

    multi method set(Str $r, Str $v) { self.set( $r, %!registers{$v} ) }
    multi method set(Str $r, Int $v) { %!registers{$r} = $v }
    multi method add(Str $r, Str $v) { self.add( $r, %!registers{$v} ) }
    multi method add(Str $r, Int $v) { %!registers{$r} += $v }
    multi method mul(Str $r, Str $v) { self.mul( $r, %!registers{$v} ) }
    multi method mul(Str $r, Int $v) { %!registers{$r} *= $v }
    multi method mod(Str $r, Str $v) { self.mod( $r, %!registers{$v} ) }
    multi method mod(Str $r, Int $v) { %!registers{$r} %= $v }

    multi method rcv(Str $v) { self.rcv( %!registers{$v} ) }
    multi method rcv(Int $v) { $v == 0 ?? Nil !! $!sound }

    multi method jgz(Str $x, Str $y) {
        self.jgz( %!registers{$x}, %!registers{$y} );
    }
    multi method jgz(Str $x, Int $y) { self.jgz( %!registers{$x}, $y ) }
    multi method jgz(Int $x, Str $y) { self.jgz( $x, %!registers{$y} ) }
    multi method jgz(Int $x, Int $y) { $!i += ( $y - 1 ) if $x > 0 }

    method process() {
        my %instruction = @!instructions[$!i];
        #%instruction.say;

        my $m = %instruction<instruction>;
        $!i++;

        return( $m, self."$m"( |%instruction<args>.cache ) );
    }

    method gist() { %!registers.gist }
}

# After each jump instruction, the program continues with the instruction to
# which the jump jumped. After any other instruction, the program continues
# with the next instruction. Continuing (or jumping) off either end of the
# program terminates it.

# For example:

{
    my @instructions = parse-instructions(q:to/EOL/.lines);
        set a 1
        add a 2
        mul a a
        mod a 5
        snd a
        set a 0
        rcv a
        jgz a -1
        set a 1
        jgz a -2
        EOL

    my $duet = Duet.new(:instructions(@instructions));
    my $sound;
    while True {
        my $ret = $duet.process;
        if $ret[0] eq 'rcv' and $ret[1].defined {
            $sound = $ret[1];
            last;
        }
    }

#     The first four instructions set a to 1, add 2 to it, square it, and then
#     set it to itself modulo 5, resulting in a value of 4.
#
#     Then, a sound with frequency 4 (the value of a) is played.
#
#     After that, a is set to 0, causing the subsequent rcv and jgz
#     instructions to both be skipped (rcv because a is 0, and jgz because a is
#     not greater than 0).
#
#     Finally, a is set to 1, causing the next jgz instruction to activate,
#     jumping back two instructions to another jump, which jumps again to the
#     rcv, which ultimately triggers the recover operation.
#
# At the time the recover operation is executed, the frequency of the last
# sound played is 4.
    is $sound, 4, "Test sound is frequency 4";
}

# What is the value of the recovered frequency (the value of the most recently
# played sound) the first time a rcv instruction is executed with a non-zero
# value?
{
    my @instructions = parse-instructions("18-input".IO.lines);
    #@instructions.say;
    my $duet = Duet.new(:instructions(@instructions));

    my $sound;
    while True {
        my $ret = $duet.process;
        if $ret[0] eq 'rcv' and $ret[1].defined {
            $sound = $ret[1];
            last;
        }
    }
    is $sound, 2951, "Processed input instructions";
}

# --- Part Two ---
#
# As you congratulate yourself for a job well done, you notice that the
# documentation has been on the back of the tablet this entire time. While you
# actually got most of the instructions correct, there are a few key
# differences. This assembly code isn't about sound at all - it's meant to be
# run twice at the same time.
#
# Each running copy of the program has its own set of registers and follows the
# code independently - in fact, the programs don't even necessarily run at the
# same speed. To coordinate, they use the send (snd) and receive (rcv)
# instructions:
#
#     snd X sends the value of X to the other program. These values wait in a
#     queue until that program is ready to receive them. Each program has its
#     own message queue, so a program can never receive a message it sent.
#
#     rcv X receives the next value and stores it in register X. If no values
#     are in the queue, the program waits for a value to be sent to it.
#     Programs do not continue to the next instruction until they have received
#     a value. Values are received in the order they are sent.
#
# Each program also has its own program ID (one 0 and the other 1); the
# register p should begin with this value.

class DuetFixed is Duet {
    has Int $.id;
    has Int @.queue;

    submethod BUILD(:$!id=0) { self.set( 'p', $!id ) }

    method rcv(Str $r) {
        #($!id, $.i, @!queue).say;
        if not @!queue {
            self.jgz( 1, 0 ); # move back to this instruction to redo
            return Nil;
        }

        self.set( $r, @!queue.shift );
    }

    method add-to-queue(Int $v) { @!queue.append($v) }
}

# For example:
{
    my @instructions = parse-instructions( q:to/EOL/.lines );
        snd 1
        snd 2
        snd p
        rcv a
        rcv b
        rcv c
        rcv d
        EOL

    my @singers = (
        DuetFixed.new(:instructions(@instructions), :id(0)),
        DuetFixed.new(:instructions(@instructions), :id(1)),
    );

    while True {
        my @res = ('queueing', 1);
        my $prev;
        while @res[0] ne 'rcv' or @res[1].defined {
            $prev = @res[0];
            @res = @singers[0].process;
            #( @singers[0].id, @singers[0].i, @res ).say;
            @singers[1].add-to-queue( @res[1] )
                if @res[0] eq 'snd';
        }
        last if $prev eq 'queueing';
        @singers = @singers.rotate(-1);
    }

# Both programs begin by sending three values to the other. Program 0 sends 1,
# 2, 0; program 1 sends 1, 2, 1. Then, each program receives a value (both 1)
# and stores it in a, receives another value (both 2) and stores it in b, and
# then each receives the program ID of the other program (program 0 receives 1;
# program 1 receives 0) and stores it in c. Each program now sees a different
# value in its own copy of register c.

    #is @got, (), "Expected instructions";

    is @singers.map(*.gist), [
        { a => 1, b => 2, c => 0, p => 1 }.gist,
        { a => 1, b => 2, c => 1, p => 0 }.gist,
    ], "Singers in expected state";

# Finally, both programs try to rcv a fourth time, but no data is waiting for
# either of them, and they reach a deadlock. When this happens, both programs
# terminate.
}
#done-testing; exit;

# It should be noted that it would be equally valid for the programs to run at
# different speeds; for example, program 0 might have sent all three values and
# then stopped at the first rcv before program 1 executed even its first
# instruction.
#
# Once both of your programs have terminated (regardless of what caused them to
# do so), how many times did program 1 send a value?
{
    my @instructions = parse-instructions("18-input".IO.lines);

    my @singers = (
        DuetFixed.new(:instructions(@instructions), :id(0)),
        DuetFixed.new(:instructions(@instructions), :id(1)),
    );

    my %snd;
    while True {
        my @res = ('queueing', 1);
        my $prev;
        while @res[0] ne 'rcv' or @res[1].defined {
            $prev = @res[0];
            @res = @singers[0].process;
            if @res[0] eq 'snd' {
                @singers[1].add-to-queue( @singers[0].sound );
                %snd{ @singers[0].id }++;
            }
        }
        #%snd.say;
        last if $prev eq 'queueing';
        @singers = @singers.rotate(-1);
    }

    is %snd{1}, 7366, "Expected number of times program 1 sent a value";
}

done-testing;
