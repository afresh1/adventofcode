#!/usr/bin/env perl6
use v6.c;

# https://www.reddit.com/r/adventofcode/comments/7kj35s/2017_day_18_solutions/drfn95w/

# Advent of Code 2017, day 18: http://adventofcode.com/2017/day/18

grammar Instructions
{
    rule TOP { ^ <instruction>+ $ }

    rule instruction { <snd> || <set> || <add> || <mul> || <mod> || <rcv> || <jgz> }

    rule snd { 'snd' $<X>=<val> }
    rule set { 'set' $<X>=<reg> $<Y>=<val> }
    rule add { 'add' $<X>=<reg> $<Y>=<val> }
    rule mul { 'mul' $<X>=<reg> $<Y>=<val> }
    rule mod { 'mod' $<X>=<reg> $<Y>=<val> }
    rule rcv { 'rcv' $<X>=<reg> }
    rule jgz { 'jgz' $<X>=<val> $<Y>=<val> }

    token reg { <[a..z]> }
    token val { <[a..z]> || '-'? \d+ }
}

# Interpretation from part one
class SoundProgram
{
    has Code @.instructions = ();
    has Bool $.verbose = False;

    has Int $.pos = 0;
    has Int %.register is default(0);
    has Int @.played = ();
    has Int @.recovered = ();

    # Actions for parsing Instructions
    method snd($/) { @!instructions.append: -> { @!played.append(self.val($<X>)) } }
    method set($/) { @!instructions.append: -> { %!register{$<X>} = self.val($<Y>) } }
    method add($/) { @!instructions.append: -> { %!register{$<X>} += self.val($<Y>) } }
    method mul($/) { @!instructions.append: -> { %!register{$<X>} *= self.val($<Y>) } }
    method mod($/) { @!instructions.append: -> { %!register{$<X>} %= self.val($<Y>) } }
    method rcv($/) { @!instructions.append: -> { @!recovered.append(@!played.tail) if self.val($<X>) } }
    method jgz($/) { @!instructions.append: -> { $!pos += self.val($<Y>)-1 if self.val($<X>) > 0 } }

    method from-input(SoundProgram:U: IO $inputfile, Bool :$verbose = False) returns SoundProgram
    {
        my $c = SoundProgram.new(:$verbose);
        Instructions.parsefile($inputfile, :actions($c)) or die "Invalid instructions!";
        return $c;
    }

    method val($x)
    {
        given $x {
            return +$x when /^ '-'? \d+ $/;
            return %!register{$x} when /^ <[a..z]> $/;
        }
        die "Invalid value or register '$x'!";
    }

    method run
    {
        while 0 ≤ $!pos < @!instructions {
            @!instructions[$!pos++]();
            say "$!pos: ", self if $!verbose;
        }
    }

    method recover returns Int
    {
        while 0 ≤ $!pos < @!instructions && !@!recovered {
            @!instructions[$!pos++]();
            say self if $!verbose;
        }
        return @!recovered[0];
    }

    method Str
    {
        "#$!pos: "
            ~ %!register.sort.map({ "$_.key()=$_.value()" }).join(', ')
            ~ (@!played ?? "; { +@!played } played" !! '')
            ~ (@!recovered ?? "; { +@!recovered } recovered" !! '');
    }
    method gist { self.Str }
}

# Correct interpretation from part two
class Program
{
    has Int $.id;
    has Code @.instructions = ();
    has Bool $.verbose = False;

    has Channel $.out .= new;
    has Channel $.in is rw;
    has Int $.pos = 0;
    has Int %.register is default(0);
    has Int $.send-count = 0;

    submethod TWEAK { %!register<p> = $!id }

    # Actions for parsing Instructions
    method snd($/) { @!instructions.append: -> { self.send(self.val($<X>)) } }
    method set($/) { @!instructions.append: -> { %!register{$<X>} = self.val($<Y>) } }
    method add($/) { @!instructions.append: -> { %!register{$<X>} += self.val($<Y>) } }
    method mul($/) { @!instructions.append: -> { %!register{$<X>} *= self.val($<Y>) } }
    method mod($/) { @!instructions.append: -> { %!register{$<X>} %= self.val($<Y>) } }
    method rcv($/) { @!instructions.append: -> { self.receive(~$<X>) } }
    method jgz($/) { @!instructions.append: -> { $!pos += self.val($<Y>)-1 if self.val($<X>) > 0 } }

    method from-input(Program:U: IO $inputfile, Int :$id, Bool :$verbose = False) returns Program
    {
        my $c = Program.new(:$id, :$verbose);
        Instructions.parsefile($inputfile, :actions($c)) or die "Invalid instructions!";
        return $c;
    }

    method connect-to(Program $p) {
        $p.in = self.out; 
        self.in = $p.out;
    }

    method val($x)
    {
        given $x {
            return +$x when /^ '-'? \d+ $/;
            return %!register{$x} when /^ <[a..z]> $/;
        }
        die "Invalid value or register '$x'!";
    }

    method send(Int $val)
    {
        $!out.send($val);
        $!send-count++;
    }

    method receive(Str $reg)
    {
        # Wait up to half a second for a value, before declaring deadlock
        for 1..6 -> $i {
            sleep 0.1 if $++;   # Sleep before all attempts but the first
            if my $val = $!in.poll {
                %!register{$reg} = $val;
                return;
            }
            else {
                say "No value to receive for program $!id, attempt #$i" if $!verbose;
            }
        }
        say "Deadlock in receive, program $!id!" if $!verbose;
        die "Deadlock in receive, program $!id!";
    }

    method done { !(0 ≤ $!pos < @!instructions) }

    method run
    {
        while !self.done {
            @!instructions[$!pos++]();
            say self if $!verbose;
        }
    }

    method run-async
    {
        start self.run;
    }

    method Str
    {
        "$!id#$!pos: "
            ~ %!register.sort.map({ "$_.key()=$_.value()" }).join(', ')
            ~ "; $!send-count sent";
    }
    method gist { self.Str }
}

multi sub MAIN(IO() $inputfile where *.f, Bool :v(:$verbose) = False)
{
    # Part 1
    my $sp = SoundProgram.from-input($inputfile, :$verbose);
    say "{ +$sp.instructions } instructions parsed." if $verbose;
    say "First recovered value: { $sp.recover // 'none' }";

    # Part 2
    say '' if $verbose;
    my $p0 = Program.from-input($inputfile, :id(0), :$verbose);
    my $p1 = Program.from-input($inputfile, :id(1), :$verbose);
    $p0.connect-to($p1);
    await Promise.allof($p0.run-async, $p1.run-async);
    say "Program 1 sent $p1.send-count() values.";
}

multi sub MAIN(Bool :v(:$verbose) = False)
{
    #MAIN($*PROGRAM.parent.child('aoc18.input'), :$verbose);
    MAIN($*PROGRAM.parent.child('18-input'), :$verbose);
}

