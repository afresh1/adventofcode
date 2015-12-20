#!/usr/local/bin/perl6
use v6;
use Test;

multi sub deliver (Int $house) { deliver( $house, $house ) }
multi sub deliver (Int $house, Int $elf, Int $max = 0, Int $per = 10) {
    return [+] ( 1..$elf ).grep({
        $house % $_ == 0 and ( $max == 0 or ( $house <= $_ * $max ) )
    }).map({ $_ * $per });
}

sub first-with(Int $presents, Int $start = 1) {
    ( $start...$presents / 10 ).first({ deliver($_) >= $presents });
}

sub first-with-deliver-fifty(Int $presents, Int $start = 1) {
    ( $start...$presents / 10 ).first({
        deliver($_, $_, 50, 11) >= $presents });
}

is deliver(1), 10, 'House 1 got 10 presents.';
is deliver(2), 30, 'House 2 got 30 presents.';
is deliver(3), 40, 'House 3 got 40 presents.';
is deliver(4), 70, 'House 4 got 70 presents.';
is deliver(5), 60, 'House 5 got 60 presents.';
is deliver(6), 120, 'House 6 got 120 presents.';
is deliver(7), 80, 'House 7 got 80 presents.';
is deliver(8), 150, 'House 8 got 150 presents.';
is deliver(9), 130, 'House 9 got 130 presents.';

is first-with(75), 6, "First house to get 75 presents is 6";

is first-with(29_000_000, 665_279), 665_280,
    'First house with 29,000,000 presents is 665,280';

is first-with-deliver-fifty(29_000_000, 705_599), 705_600,
    'First house with 29,000,000 presents is 705,600 when elves deliver 11 presents to 50 houses';

done-testing;
