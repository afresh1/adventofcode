#!/usr/bin/perl
use v5.20;
use warnings;

use Test::More;

my %instructions = (
    '(' => 1,
    ')' => -1
);

sub final_floor {
    my ($input) = @_;

    my $floor = 0;
    $floor += ( $instructions{$_} || 0 ) for split //, $input;

    return $floor;
}

sub first_basement {
    my ($input) = @_;

    my $i     = 0;
    my $floor = 0;
    foreach (split //, $input) {
        if (my $change = $instructions{$_}) {
            $floor += $change;
            $i++;
            return $i if $floor < 0;
        }
    }

    return $i;
}

open my $fh, '<', '1-input' or die $!;
my $data = do { local $/ = undef; readline($fh) };
close $fh;

is final_floor("(())"),    0;
is final_floor("()()"),    0;
is final_floor("((("),     3;
is final_floor("(()(()("), 3;
is final_floor("))((((("), 3;
is final_floor("())"),     -1;
is final_floor("))("),     -1;
is final_floor(")))"),     -3;
is final_floor(")())())"), -3;

is final_floor($data), 138, "With data it's 138";

is first_basement(")"),     1;
is first_basement("()())"), 5;
is first_basement($data), 1771, "With data, it's 1771";

done_testing;
