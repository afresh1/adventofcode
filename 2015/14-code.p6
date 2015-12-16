#!/usr/local/bin/perl6
use v6;
use Test;

sub decode (@reindeer) {
    my %reindeer;
    for @reindeer {
        .match(/
            ^
                        $<name>=[\w+]
            .* fly \s+  $<speed>=[\d+] \s+ km\/s
            \s+ for \s+ $<fly>=[\d+]
            .* \s+ rest
            \s+ for \s+ $<rest>=[\d+]
        /);

        %reindeer{$/<name>} = {
            speed => $/<speed>.Int,
            fly   => $/<fly>.Int,
            rest  => $/<rest>.Int,
        };
    }
    return %reindeer;
}

sub travel (%reindeer, Int $seconds) {
    my %travel = %reindeer.kv.map( -> $k, $v { $k => {
        distance => 0,
        points   => 0,
        action   => 'fly',
        seconds  => $v<fly>,
    } } );

    for [1..$seconds] {
        for %travel.kv -> $name, $t {
            $t<distance> += %reindeer{$name}<speed> if $t<action> eq 'fly';

            $t<seconds>--;
            if $t<seconds> == 0 {
                $t<action> = $t<action> eq 'fly' ?? 'rest' !! 'fly';
                $t<seconds> = %reindeer{$name}{ $t<action> };
            }
        }

        my $max-distance = %travel.values.map({$_<distance>}).max;
        $_<points>++
            for %travel.values.grep({ $_<distance> == $max-distance });
    }
    return %travel.kv.map( -> $k, $v { $k => {
        distance => $v<distance>,
        points   => $v<points>,
    } } ).hash;
}

my @reindeer = (
    'Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds.',
    'Dancer can fly 16 km/s for 11 seconds, but then must rest for 162 seconds.',
);

is-deeply decode(@reindeer), {
    Comet  => { fly => 10, rest => 127, speed => 14 },
    Dancer => { fly => 11, rest => 162, speed => 16 },
}, "Correct sample decode";

is-deeply travel( decode(@reindeer), 1000 ), {
    Comet  => { distance => 1120, points => 312 },
    Dancer => { distance => 1056, points => 689 },
}, "Correct sample travel";

my %travel = travel( decode("14-input".IO.lines), 2503 );
is-deeply %travel, {
    Blitzen => { distance => 2496, points => 5 },
    Comet   => { distance => 2493, points => 22 },
    Cupid   => { distance => 2592, points => 13 },
    Dancer  => { distance => 2516, points => 1 },
    Dasher  => { distance => 2460, points => 0 },
    Donner  => { distance => 2655, points => 414 },
    Prancer => { distance => 2484, points => 153 },
    Rudolph => { distance => 2540, points => 887 },
    Vixen   => { distance => 2640, points => 1059 },
}, "Correct input travel";

is %travel.values.map({ $_<distance> }).max, 2655, "Donner went furthest";
is %travel.values.map({ $_<points>   }).max, 1059, "With the most points";

pass;
done-testing;
