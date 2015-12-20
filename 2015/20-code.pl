#!/usr/bin/perl
use v5.20;
use warnings;

use experimental 'signatures';

use Test::More;

sub first_house ( $presents, $houses_per_elf = 0 ) {
    my $max_houses = int $presents / 10;

    my @deliveries;
    for my $i ( 1 .. $max_houses ) {

        my $j = $i;
        my $to_deliver = $houses_per_elf || -1;

        while ( $j <= $max_houses and $to_deliver) {
            if ($houses_per_elf) {
                $deliveries[$j] += $i * 11;
                $to_deliver--;
            }
            else {
                $deliveries[$j] += $i * 10;
            }

            $j += $i;
        }

        #diag "$i: $deliveries[$i]" unless $i % 10_000;
        return $i if $deliveries[$i] >= $presents;
    }

    return;
}

is first_house(75), 6, "House 6 is the first house with 75 presents";

is first_house(29_000_000), 665_280,
    "House 665,280 is the first house with 29 million presents";

is first_house(29_000_000, 50), 705600,
    "House 705,600 is the first house with 29 million presents if elves only deliver to 50 houses";

done_testing;
