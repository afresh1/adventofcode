#!/usr/local/bin/perl6
use v6;
use Test;

class Instruction {
    has Str $.set where { < on off toggle >.first($_) };
    has Int $.x1 where { $_ >= 0 and $_ <= 999 };
    has Int $.y1 where { $_ >= 0 and $_ <= 999 };
    has Int $.x2 where { $_ >= 0 and $_ <= 999 };
    has Int $.y2 where { $_ >= 0 and $_ <= 999 };

    multi method new(Str $instruction) {
        $instruction ~~ m{
            $<set>=( [ <?after turn \s+ > [on|off] ] | toggle )
            \s+
            $<x1>=( \d+ ) \, $<y1>=( \d+ )
            \s through \s
            $<x2>=( \d+ ) \, $<y2>=( \d+ )
        };
        my %args = $/.pairs;
        %args{'set'} = %args{'set'}.Str;
        %args{$_} = %args{$_}.Int for %args.keys.grep({ not $_ ~~ 'set' });
        return self.new(|%args);
    }
}

class Grid {
    has Array @!lights;
    has Int $!count = 0;

    has Str $.type is readonly where { < switch dimmer >.first($_) } = 'switch';
    has Int $.x is readonly = 999;
    has Int $.y is readonly = 999;

    method switch(Instruction $ins) {
        for ($ins.x1 .. $ins.x2) -> $x {
            for ($ins.y1 .. $ins.y2) -> $y {
                if ($!type eq 'switch') {
                    my $old = @!lights[$x][$y] || 0;
                    my $v
                        = $ins.set eq 'toggle' ?? $old ?? 0 !! 1
                        !! $ins.set eq 'on'    ?? 1
                        !!                        0;

                    @!lights[$x][$y] = $v;
                    $!count += $v - $old;
                }
                elsif ($!type eq 'dimmer') {
                    my $v
                        = $ins.set eq 'toggle' ?? 2
                        !! $ins.set eq 'on'    ?? 1
                        !!                        -1;

                    @!lights[$x][$y] += $v;
                    $!count += $v;

                    if ($@!lights[$x][$y] < 0) {
                        $!count -= @!lights[$x][$y];
                        @!lights[$x][$y] = 0;
                    }
                }
            }
        }
        return self;
    }

    multi method Str() {
        my @str;
        for (0..$.x) -> $x {
            my @line;
            for (0..$.y) -> $y {
                @line.push( @!lights[$x][$y] || 0 );
            }
            @str.push( @line.join("") );
        }
        return @str.join("\n");
    }

    multi method Int() {
        return $!count;
        my $count = 0;
        for (0..$.x) -> $x {
            for (0..$.y) -> $y {
                 $count += @!lights[$x][$y] || 0;
             }
         }
         return $count;
    }
}

is-deeply Instruction.new("turn on 1,2 through 3,4"),
    Instruction.new( set => "on", x1 => 1, y1 => 2, x2 => 3, y2 => 4 ),
    "'turn on 1,2 through 3,4' parses string properly";

is-deeply Instruction.new("turn off 1,2 through 3,4"),
    Instruction.new( set => "off", x1 => 1, y1 => 2, x2 => 3, y2 => 4 ),
    "'turn off 1,2 through 3,4' parses string properly";

is-deeply Instruction.new("toggle 1,2 through 3,4"),
    Instruction.new( set => "toggle", x1 => 1, y1 => 2, x2 => 3, y2 => 4 ),
    "'toggle 1,2 through 3,4' parses string properly";

subtest {
    is Grid.new.switch(Instruction.new("turn on 0,0 through 999,999")).Int,
        1_000_000,
        "Turn on all 1 million lights";
}, "turn on 0,0 through 999,999";

subtest {
    is Grid.new
        .switch(Instruction.new("toggle 10,0 through 900,0"))
        .switch(Instruction.new("toggle 0,0 through 999,0"))
        .Int, 109, "One Hundred and Nine lights are on";
}, "toggle 0,0 through 999,0";

subtest {
    is Grid.new
        .switch(Instruction.new("turn on 490,490 through 509,509"))
        .switch(Instruction.new("turn off 499,499 through 500,500"))
        .Int, 396, "Three hundred and Ninty Six lights are on";
}, "turn off 499,499 through 500,500";

subtest {
    my $g = Grid.new;
    $g.switch(Instruction.new($_)) for "6-input".IO.lines;
    is $g.Int, 543903, "Total lights are 543,903";
}, "Input Switch";

subtest {
    my $g = Grid.new(type => 'dimmer');
    $g.switch(Instruction.new($_)) for "6-input".IO.lines;
    is $g.Int, 14687245, "Total brightness is 14,687,245";
}, "Input Dimmer";

done-testing;
