#!/usr/local/bin/perl6
use v6;
use Test;

sub wrapping_needed_for(Str $dimensions) {
    my @d     = $dimensions.split('x').map({.Int}).sort;
    my @sides = @d.combinations(2).map({ [*] $_ });

    my %r = (
        volume    => @d.reduce(&[*]),
        perimeter => ( 2 * @d[0,1].reduce(&[+]) ),
        area      => @sides.map({ 2 * $_ }).reduce(&[+]),

        extra     => @sides[0],
    );

    %r{'paper'}  = %r{'area'} + %r{'extra'};
    %r{'ribbon'} = %r{'perimeter'} + %r{'volume'};

    return %r;
}

is-deeply wrapping_needed_for("2x3x4"), {
    perimeter => 10,
    volume    => 24,
    area      => 52,
    extra     => 6,
    paper     => 58,
    ribbon    => 34
}, "2x3x4 box";

is-deeply wrapping_needed_for("1x1x10"), {
    perimeter => 4,
    volume    => 10,
    area      => 42,
    extra     => 1,
    paper     => 43,
    ribbon    => 14
}, "1x1x10 box";

is-deeply wrapping_needed_for("4x23x21"), {
    'perimeter' => 50,
    'extra'     => 84,
    'ribbon'    => 1982,
    'volume'    => 1932,
    'area'      => 1318,
    'paper'     => 1402
}, "4x23x21 box";

my %total = ( paper => 0, ribbon => 0 );
for "2-input".IO.lines -> $line {
    my $wrapping = wrapping_needed_for($line);
    %total{$_} += $wrapping{$_} for %total.keys;
}

is %total{'paper'},  1598415, "Total paper is 1598415 square feet";
is %total{'ribbon'}, 3812909, "Total ribbon is 3812909 linear feet";

done-testing;
