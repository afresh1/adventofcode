#!/usr/local/bin/perl6
use v6;
use Test;

class Computer {
    has UInt $.a is rw = 0;
    has UInt $.b is rw = 0;
    has Int $.instruction is rw = 0;
    has @.instructions;

    my %reg;

    method hlf ($r) { %reg{$r} div= 2 };
    method tpl ($r) { %reg{$r} *= 3 }
    method inc ($r) { %reg{$r} += 1 }

    # minus one because we add another in the loop.
    method jmp (    $offset) { $.instruction += $offset - 1 }
    method jie ($r, $offset) { self.jmp($offset) if %reg{$r} mod 2 == 0 }
    method jio ($r, $offset) { self.jmp($offset) if %reg{$r} == 1 }

    method run {
        %reg<a> := $.a;
        %reg<b> := $.b;

        while $.instruction <= @.instructions.end {
            my ($ins, $args) = @.instructions[ $.instruction ].kv;
            my $method = self.^find_method($ins);
            #say [ $ins, |$args ].perl;
            self.$method( |$args );
            $.instruction++;
        }
    }

}

sub parse (@lines) {
    @lines.grep({ .chars }).map({
        my ($k, $v) = .split(' ', 2).flat;
        $k => $v.split(', ');
    });
}

subtest {
    my @instructions = parse( q{
inc a
jio a, +2
tpl a
inc a
}.lines);

    my $c = Computer.new( :instructions(@instructions) );
    $c.run;
    is $c.a, 2, "Register A is two";

}, "Test Instructions";

subtest {
    my @instructions = parse( "23-input".IO.lines );

    my $c = Computer.new( :instructions(@instructions) );
    $c.run;
    is $c.b, 184, "Register B is 184";

}, "Real Instructions";

subtest {
    my @instructions = parse( "23-input".IO.lines );

    my $c = Computer.new( :instructions(@instructions), :a(1) );
    $c.run;
    is $c.b, 231, "Register B is 231";

}, "Real Instructions, A starts at 1";


done-testing;
