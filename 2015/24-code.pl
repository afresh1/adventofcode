#!/usr/bin/perl
use v5.20;
use warnings;

use experimental 'signatures';

use Test::More;

sub unsacked ($packages, $sack) {
    my %sack = map { $_ => 1 } @{ $sack };
    return grep { !$sack{$_} } @{ $packages };
}

sub sum (@vs) { my $v = 0; $v += $_ for @vs; return $v }
sub mul (@vs) { my $v = 1; $v *= $_ for @vs; return $v }
sub min (@vs) { my $v = "Inf"; $v > $_ and $v = $_ for @vs; return $v }

sub estimate_best_sack (
    $packages,
    $count      = 3,
    $weight     = 0,
    $first_sack = 1,
    $have       = [],
    $remaining  = $weight,
) {
    unless ($weight) {
        $weight += $_ for @{ $packages };
        $weight /= $count;
        $remaining = $weight;
    }
    return unless @{ $packages };
    return if $remaining > sum @{ $packages };

    my $best = "Inf";
    my @sacks;
    for my $w (@{ $packages }) {
        # We know it won't work due to having sorted input
        next if @{ $have } and $have->[-1] <= $w;

        my @sack = ( @{ $have }, $w );
        my @unsacked = sort { $b <=> $a } unsacked( $packages, \@sack );

        my $b;
        if ($w < $remaining) {
            # No need to check further if we already have a better solution
            last if @sack + 1 > $best;

            my @s = estimate_best_sack(
                $packages, $count, $weight,        $first_sack,
                \@sack,             $remaining - $w
            );

            if (@s) {
                push @sacks, @s;
                $b = min map { scalar @{ $_ } } @s;
            }
        }
        elsif ($w == $remaining) {
            if (@unsacked) {
                my @sub_sacks = estimate_best_sack(
                    \@unsacked, $count - 1, $weight, 0 );

                if (@sub_sacks) {
                    push @sacks, \@sack;
                    $b = @sack;
                }
            }
            else {
                push @sacks, \@sack;
                $b = @sack;
            }
        }


        # We only care that a solution exists, not how many
        last if not $first_sack and @sacks;

        $best = $b if $b and $best > $b;
    }

    return @sacks;
}

sub estimate_best ($packages, $count = 3) {
    my @sacks = estimate_best_sack( $packages, $count );

    my $best;
    for ( sort { @{ $a } <=> @{ $b } } @sacks ) {
        if ($best) {
            $best = $_ if @{ $best } == @{ $_ }
                and mul( @{ $best } ) > mul( @{ $_ } );
        }
        else {
            $best = $_;
        }
        #diag "[@{$_}], [@{$best}]";
    }
    return $best;
}

subtest "Sample Packages" => sub {
    my @packages = ( 7..11, 1..5 );
    is_deeply estimate_best( [sort { $b <=> $a } @packages] ), [11, 9],
        "Estimated best is the same";
};

subtest "Sample Packages" => sub {
    my @packages = ( 7..11, 1..5 );
    is_deeply estimate_best( [sort { $b <=> $a } @packages], 4 ), [11, 4],
        "Estimated best is the same";
};

open my $fh, '<', '24-input' or die $!;
my @packages = readline($fh);
close $fh;
chomp @packages;

subtest "Real Packages in three sacks" => sub {
    my $estimated = estimate_best([ sort { $b <=> $a } @packages ]);
    is_deeply $estimated, [113, 109, 107, 103, 83, 1],
        "Estimated best correct";

    is mul(@{ $estimated }), 11266889531, "Expected quantum entanglement";
};

subtest "Real Packages in four sacks" => sub {
    my $estimated = estimate_best([ sort { $b <=> $a } @packages ], 4);
    is_deeply $estimated, [113, 109, 103, 61, 1],
        "Estimated best correct";

    is mul(@{ $estimated }), 77387711, "Expected quantum entanglement";
};

done_testing;
