#!/usr/local/bin/perl6
use v6;
use Test;

class Elevator {
    has Str $!directions;
    has Int $!floor = 0;
    has Int $!first_basement;

    my %movements = (
        '(' =>  1,
        ')' => -1,
    );
    sub move(Str $d) { return %movements{$d} || 0 }

    method new ($directions) { return self.bless(:$directions) }
    submethod BUILD (:$!directions) {}

    method run {
        my $i = 0;
        for ($!directions.split("", :skip-empty)) {
            next unless .chars; # bug in 2015.10
            $i++;
            self.go($_);
            $!first_basement //= $i if $!floor < 0;
        }
        return $!floor;
    }

    method go(Str $d) { $!floor += move $d }
    method first_basement() { return $!first_basement }
}

my %final_floor = (
    "(())"    => 0,
    "()()"    => 0,
    "((("     => 3,
    "(()(()(" => 3,
    "))(((((" => 3,
    "())"     => -1,
    "))("     => -1,
    ")))"     => -3,
    ")())())" => -3,
);

for (keys %final_floor) {
    is Elevator.new($_).run, %final_floor{$_},
        "[$_] Final Floor is %final_floor{$_}";
}

my %first_basement = (
    ")"     => 1,
    "()())" => 5,
);

for (keys %first_basement) {
    my $e = Elevator.new($_);
    $e.run;
    is $e.first_basement, %first_basement{$_},
        "[$_] Final Floor is %first_basement{$_}";
}

subtest {
    my $directions = "1-input".IO.slurp;

    my $e = Elevator.new($directions);
    is $e. run,            138,  "Final Floor 138";
    is $e. first_basement, 1771, "First basement is 1771";

}, "Input file";

done-testing;
