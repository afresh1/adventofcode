#!/usr/local/bin/perl
use v6;
use Test;
#exit;

sub decode (Str $ingredient) {
    my ($name, $properties) = $ingredient.split(': ');
    my %properties = $properties.split(', ').split(' ')
        .hash.kv.map( -> $k, $v { $k => $v.Int });

    return ( $name => %properties );
}


sub score (%ingredients, @tsp) {
    my %score;
    for @tsp.grep({ .WHAT.^name eq 'Hash' }) -> %t {
        for %ingredients{ %t<name> }.kv -> $k, $v {
            #diag "$k: " ~ ( %score{$k} || 0 ) ~ " += ( $v * %t<value> )";
            %score{$k} += ( $v * %t<value> );
        }
    }

    for %score.kv -> $k, $v { %score{$k} = 0 if $v < 0 }

    my $calories = %score<calories>:delete;
    my $score = %score.keys.reduce({
        my $v = %score{$^a}:exists ?? %score{$^a} !! $^a;
        #diag "$^a [$v] * $^b = " ~ %score{$^b} * $v;
        %score{$^b} * $v;
    });

    #diag { score => $score, calories => $calories, subscores => %score }.gist;
    return { score => $score, calories => $calories.Int };
}

sub find-best-score (%ingredients, @tsp = [], $calories = False ) {
    my @t;
    if @tsp {
        # Not sure why .clone didn't work
        @t = ( |@tsp[1..*], @tsp[0] )
            .map({ .WHAT.^name ne 'Hash' ?? $_
                !! [ name => $_<name>, value => $_<value> ].hash });
    }
    else {
        @t = %ingredients.keys.map({ ( name => $_, value => 0 ).hash });
        @t.push(False);
        @t[0]<value> = 100;
    }

    my %best = ( score => -2 );
    return %best unless @t[0];

    while @t[0] and @t[0]<value> > 0 {
        my %score = score(%ingredients, @t);
        %score<score> = -1 if $calories and %score<calories> != $calories;
        %best = %score if %score<score> > %best<score>;

        last unless @t[1];

        my %next = find-best-score( %ingredients, @t, $calories );
        %best = %next if %next<score> > %best<score>;

        @t[0]<value>--;
        @t[1]<value>++;
    }

    diag [
        @tsp.map({ .WHAT.^name eq 'Hash' ?? sprintf "%2d", $_<value> !! 'XX' }),
        @t.map(  { .WHAT.^name eq 'Hash' ?? sprintf "%2d", $_<value> !! 'XX' }),
        %best,
    ].gist;

    return %best;
}

my @test-ingredients = (
    'Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8',
    'Cinnamon: capacity 2, durability 3, flavor -2, texture -1, calories 3',
);

my %test-ingredients = @test-ingredients.map({ decode $_ }).hash;
is-deeply %test-ingredients, {
    Butterscotch => {
        calories   => 8, capacity   => -1, durability => -2,
        flavor     => 6, texture    =>  3
    },
    Cinnamon => {
        calories   =>  3, capacity   =>  2, durability => 3,
        flavor     => -2, texture    => -1
    },
};

is-deeply find-best-score(%test-ingredients),
    { score => 62842880, calories => 520 };

is-deeply find-best-score(%test-ingredients, [], 500 ),
    { score => 57600000, calories => 500 };

done-testing; exit;

my %ingredients = "15-input".IO.lines.map({ decode $_ }).hash;
#diag %ingredients.gist;

is-deeply find-best-score(%ingredients),
    { score => 18965440, calories => 0 };

is-deeply find-best-score(%ingredients, [], 500),
    { score => 0, calories => 500 };

done-testing;
