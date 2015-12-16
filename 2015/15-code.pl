#!/usr/bin/perl
use v5.20;
use warnings;
use Test::More;

use experimental 'signatures';

sub decode ($ingredient) {
    my ($name, $properties) = split /: /, $ingredient;
    my %properties = map { split / / } split /, /, $properties;

    return ( $name => \%properties );
}


sub score ($ingredients, $tsp) {
    my %score;
    foreach my $t (@{$tsp}) {
        next unless $t;
        my $ingredient = $ingredients->{ $t->{name} };

        foreach my $k ( keys %{ $ingredient } ) {
            my $v = $ingredient->{$k};
            #diag "$k: " . ( $score{$k} || 0 ) . " += ( $v * $t->{value} )";
            $score{$k} += ( $v * $t->{value} );
        }
    }

    for my $k ( keys %score ) {
        $score{$k} = 0 if $score{$k} < 0;
    }

    my $calories = delete $score{calories};
    my $score = 1;
    $score *= $score{$_} for keys %score;

    #diag explain { score => $score, calories => $calories, subscores => \%score };
    return ( score => $score, calories => $calories );
}

sub find_best_score ($ingredients, $tsp = [], $calories = 0 ) {
    my @t;
    if (@{$tsp}) {
        @t = map {
            ref($_) ? { name => $_->{name}, value => $_->{value} } : $_
        } ( @{$tsp}[ 1 .. $#$tsp ], @{$tsp}[0] );
    }
    else {
        @t = map { { name => $_, value => 0 } } keys %{ $ingredients };
        push @t, undef;
        $t[0]{value} = 100;
    }

    my %best = ( score => -2 );
    return %best unless $t[0];

    while ($t[0] and $t[0]{value} > 0) {
        my %score = score($ingredients, \@t);
        $score{score} = -1 if $calories and $score{calories} != $calories;
        %best = %score if $score{score} > $best{score};

        last unless $t[1];

        my %next = find_best_score( $ingredients, \@t, $calories );
        %best = %next if $next{score} > $best{score};

        $t[0]{value}--;
        $t[1]{value}++;
    }

    diag join(' | ',
        join(' ', map { ref $_ ? sprintf "%2d", $_->{value} : 'XX' } @{$tsp} ),
        join(' ', map { ref $_ ? sprintf "%2d", $_->{value} : 'XX' } @t      ),
        "calories => $best{calories}, score => $best{score}",
    ) if 0;

    return %best;
}

my @test_ingredients = (
    'Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8',
    'Cinnamon: capacity 2, durability 3, flavor -2, texture -1, calories 3',
);

my %test_ingredients = map { decode($_) } @test_ingredients;
is_deeply \%test_ingredients, {
    Butterscotch => {
        calories   => 8, capacity   => -1, durability => -2,
        flavor     => 6, texture    =>  3
    },
    Cinnamon => {
        calories   =>  3, capacity   =>  2, durability => 3,
        flavor     => -2, texture    => -1
    },
};

is_deeply { find_best_score(\%test_ingredients) },
    { score => 62842880, calories => 520 };

is_deeply { find_best_score(\%test_ingredients, [], 500 ) },
    { score => 57600000, calories => 500 };

open my $fh, '<', "15-input" or die $!;
my %ingredients = map { decode($_) } readline($fh);
close $fh;

is_deeply { find_best_score(\%ingredients) },
    { score => 18965440, calories => 554 };

is_deeply { find_best_score(\%ingredients, [], 500) },
    { score => 15862900, calories => 500 };

done_testing;
