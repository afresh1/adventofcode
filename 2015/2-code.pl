#!/usr/bin/perl
use v5.20;
use warnings;

use Test::More;

sub wrapping_needed_for {
    my ($box) = @_;
    my ( $x, $y, $z ) = sort { $a <=> $b } split /x/, $box;

    my @sides = ( $x * $y, $y * $z, $x * $z, );

    my $perimeter = 2 * ( $x + $y );
    my $volume    = $x * $y * $z;
    my $area      = 0;
    $area += 2 * $_ for @sides;

    my $extra = $sides[0];    # smallest side

    my $paper  = $area + $extra;
    my $ribbon = $perimeter + $volume;

    #note "Paper:  $box = $area + $extra = $paper";
    #note "Ribbon: $box = $perimeter + $volume = $ribbon";

    return {
        perimeter => $perimeter,
        volume    => $volume,
        area      => $area,
        extra     => $extra,

        paper  => $paper,
        ribbon => $ribbon,
    };
}

is_deeply wrapping_needed_for("2x3x4"), {
    perimeter => 10,
    volume    => 24,
    area      => 52,
    extra     => 6,
    paper     => 58,
    ribbon    => 34
}, "2x3x4 box";

is_deeply wrapping_needed_for("1x1x10"), {
    perimeter => 4,
    volume    => 10,
    area      => 42,
    extra     => 1,
    paper     => 43,
    ribbon    => 14
}, "1x1x10 box";

is_deeply wrapping_needed_for("4x23x21"), {
    'perimeter' => 50,
    'extra'     => 84,
    'ribbon'    => 1982,
    'volume'    => 1932,
    'area'      => 1318,
    'paper'     => 1402
}, "4x23x21 box";

open my $fh, '<', '2-input';
my %total = ( paper => 0, ribbon => 0 );
while ( readline($fh) ) {
    chomp;
    my $wrapping = wrapping_needed_for($_);
    my $line = $_;
    foreach (sort keys %total) {
        $total{$_}  += $wrapping->{$_};
        #say "$_: $line = $wrapping->{$_} [$total{$_}]";
    }
}

is $total{paper},  1598415, "Total paper is 1598415 square feet";
is $total{ribbon}, 3812909, "Total ribbon is 3812909 linear feet";

done_testing;
