#!/usr/bin/perl
use v5.20;
use warnings;

use Test::More;

sub deliver {
    my ($directions, $delivery_people) = @_;
    $delivery_people ||= 1;

    my %x = ( '<' => -1, '>' => +1 );
    my %y = ( 'v' => -1, '^' => +1 );

    my @x;
    my @y;

    my @presents;
    foreach my $i ( 0 .. $delivery_people - 1 ) {
        @x[$i] = 0;
        @y[$i] = 0;
        $presents[$i] = { $x[$i] => { $y[$i] => 1 } };
    }

    my $i = 0;
    for ( split //, $directions ) {
        $x[$i] += $x{$_} || 0;
        $y[$i] += $y{$_} || 0;

        $presents[$i]{ $x[$i] }{ $y[$i] }++;

        $i = ( $i + 1 ) % $delivery_people;
    }

    return \@presents;
}

sub total_houses_santa {
    my ($directions) = @_;
    my $presents = deliver($directions);

    my $total = 0;

    foreach my $delivery ( @{$presents} ) {
        foreach my $x ( keys %{$delivery} ) {
            foreach my $y ( keys %{ $delivery->{$x} } ) {
                $total++ if $delivery->{$x}->{$y};
            }
        }
    }

    return $total;
}

sub total_houses_both {
    my ($directions) = @_;
    my $presents = deliver( $directions, 2 );

    my $total = 0;

    foreach my $x ( keys %{ $presents->[0] } ) {
        foreach my $y ( keys %{ $presents->[0]->{$x} } ) {
            $total++ if $presents->[0]->{$x}->{$y};
        }
    }

    foreach my $x ( keys %{ $presents->[1] } ) {
        foreach my $y ( keys %{ $presents->[1]->{$x} } ) {
            $total++
                if $presents->[1]->{$x}->{$y}
                and not $presents->[0]->{$x}->{$y};
        }
    }

    return $total;
}

subtest '>' => sub {
    my $directions = '>';
    is_deeply deliver($directions), [ { 0 => { 0 => 1 }, 1 => { 0 => 1 } } ];
    is_deeply total_houses_santa($directions), 2;

    is_deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 1 }, 1 => { 0 => 1 } },
        { 0 => { 0 => 1 } }
    ];
    is_deeply total_houses_both($directions), 2;
};

subtest '^v' => sub {
    my $directions = '^v';
    is_deeply deliver($directions), [ { 0 => { 0 => 2,  1 => 1 } } ];
    is_deeply total_houses_santa($directions), 2;

    is_deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 1, 1  => 1 } },
        { 0 => { 0 => 1, -1 => 1 } }
    ];
    is_deeply total_houses_both($directions), 3;
};

subtest '^>v<' => sub {
    my $directions = '^>v<';
    is_deeply deliver($directions),
        [ { 0 => { 0 => 2, 1 => 1 }, 1 => { 0 => 1, 1 => 1 } } ];
    is_deeply total_houses_santa($directions), 4;

    is_deeply deliver( $directions, 2 ), [
        { 0 => { 0 => 2, 1 => 1 } },
        { 0 => { 0 => 2 }, 1 => { 0 => 1 } }
    ];
    is_deeply total_houses_both($directions), 3;
};

subtest '^v^v^v^v^v' => sub {
    my $directions = '^v^v^v^v^v';
    is_deeply deliver($directions), [ { 0 => { 0 => 6, 1 => 5 } } ];
    is_deeply total_houses_santa($directions), 2;

    is_deeply deliver( $directions, 2 ), [
        { 0 => { 1  => 1, 5 => 1, 4  => 1, 3  => 1, 2  => 1, 0  => 1 } },
        { 0 => { -5 => 1, 0 => 1, -4 => 1, -3 => 1, -1 => 1, -2 => 1 } }
    ];
    is_deeply total_houses_both($directions), 11;
};

open my $fh, '<', '3-input' or die $!;
my $input = do { local  $/ = undef; readline($fh) };
close $fh;

is total_houses_santa($input), 2592;
is total_houses_both($input),  2360;

done_testing;
