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
    token TOP {
        <snd>
      | <set>
      | <add>
      | <sbu>
      | <mul>
      | <mod>
      | <rcv>
      | <jgz>
      | <jnz>
  }

#     snd X plays a sound with a frequency equal to the value of X.
    rule snd { 'snd' <value> }

#     set X Y sets register X to the value of Y.
    rule set { 'set' <register> <value> }

#     add X Y increases register X by the value of Y.
    rule add { 'add' <register> <value> }

#     sub X Y decreases register X by the value of Y.
    rule sbu { 'sub' <register> <value> }

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

#     jnz X Y jumps with an offset of the value of Y, but only if the value of
#     X is not zero. (An offset of 2 skips the next instruction, an offset of
#     -1 jumps to the previous instruction, and so on.)
    rule jnz { 'jnz' <value> <value> }

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
    method sbu($/) { make ( $<register>.made, $<value>.made ) }
    method mul($/) { make ( $<register>.made, $<value>.made ) }
    method mod($/) { make ( $<register>.made, $<value>.made ) }
    method rcv($/) { make ( $<value>.made ) }
    method jgz($/) { make $<value>.map(*.made) }
    method jnz($/) { make $<value>.map(*.made) }

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

sub EXPORT {
    %(
        '&parse-instructions' => &parse-instructions;
    )
}

