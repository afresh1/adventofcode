#!perl6
use Test;
use lib IO::Path.new($?FILE).parent.add('lib');
use Instructions;
use Duet;
use DuetFixed;

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
