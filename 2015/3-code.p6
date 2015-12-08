#!/usr/local/bin/perl6
use v6;
use Test;

sub deliver(Str $directions, Int $delivery_people = 1) {
    state %moves = (
        x => { '>' => 1, '<' => -1 },
        y => { '^' => 1, 'v' => -1 },
    );

    my ( @x, @y, @presents );
    for 0 .. $delivery_people - 1 -> $i {
        @x[$i] = 0;
        @y[$i] = 0;

        @presents[$i]{@x[$i]}{@y[$i]} = 1;
    }

    my $i = 0;
    for $directions.split('', :skip-empty) {
        @x[$i] += %moves{'x'}{$_} || 0;
        @y[$i] += %moves{'y'}{$_} || 0;

        @presents[$i]{@x[$i]}{@y[$i]}++;
        #diag "[$_] [$i][@x[$i]][@y[$i]] = @presents[$i]{@x[$i]}{@y[$i]}";

        $i = ( $i + 1 ) % $delivery_people;
    };

    return @presents;
}

sub total_houses_santa(Str $directions) {
    my @presents = deliver($directions);

    my $houses = 0;
    for @presents[0].keys -> $x {
        for @presents[0]{$x}.keys -> $y {
            $houses++ if @presents[0]{$x}{$y};
        }
    }
    return $houses;
}

sub total_houses_both(Str $directions) {
    my @presents = deliver($directions, 2);

    my $houses = 0;

    for @presents[0].keys -> $x {
        for @presents[0]{$x}.keys -> $y {
            $houses++ if @presents[0]{$x}{$y};
        }
    }

    for @presents[1].keys -> $x {
        for @presents[1]{$x}.keys -> $y {
            $houses++ if @presents[1]{$x}{$y} and not @presents[0]{$x}{$y};
        }
    }

    return $houses;
}

subtest {
    my $directions = '>';
    is-deeply deliver($directions), [ ${ 0 => { 0 => 1 }, 1 => { 0 => 1 } } ];
    is-deeply total_houses_santa($directions), 2;

    is-deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 1 }, 1 => { 0 => 1 } },
        { 0 => { 0 => 1 } }
    ];
    is-deeply total_houses_both($directions), 2;
}, '>';

subtest {
    my $directions = '^v';
    is-deeply deliver($directions), [ ${ 0 => { 0 => 2,  1 => 1 } } ];
    is-deeply total_houses_santa($directions), 2;

    is-deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 1, 1  => 1 } },
        { 0 => { 0 => 1, -1 => 1 } }
    ];
    is-deeply total_houses_both($directions), 3;
}, '^v';

subtest {
    my $directions = '^>v<';
    is-deeply deliver($directions),
        [ ${ 0 => { 0 => 2, 1 => 1 }, 1 => { 0 => 1, 1 => 1 } } ];
    is-deeply total_houses_santa($directions), 4;

    is-deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 2, 1 => 1 } },
        { 0 => { 0 => 2 }, 1 => { 0 => 1 } }
    ];
    is-deeply total_houses_both($directions), 3;
}, '^>v<';

subtest {
    my $directions = '^v^v^v^v^v';
    is-deeply deliver($directions), [ ${ 0 => { 0 => 6, 1 => 5 } } ];
    is-deeply total_houses_santa($directions), 2;

    is-deeply deliver( $directions, 2 ), [
        { 0 => { 1  => 1, 5 => 1, 4  => 1, 3  => 1, 2  => 1, 0  => 1 } },
        { 0 => { -5 => 1, 0 => 1, -4 => 1, -3 => 1, -1 => 1, -2 => 1 } }
    ];
    is-deeply total_houses_both($directions), 11;
}, '^v^v^v^v^v';

subtest {
    my $input = "3-input".IO.slurp;

    is total_houses_santa($input), 2592;
    is total_houses_both($input),  2360;
}, "Input";

done-testing;
