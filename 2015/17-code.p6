#!/usr/local/bin/perl6
use v6;
use Test;

sub store ( Int $want, @containers ) {
    return False unless @containers;
    return False if $want < 1;
    my @combinations;

    my @c = @containers;
    while (@c) {
        my $current = @c.shift;
        push @combinations, [ $current ] if $want == $current;

        my $remaining = $want - $current;
        last if $remaining > [+] @c;

        my @next = store( $remaining, @c ).grep({ $_ })
            .map({ .unshift($current) });

        @combinations.append( @next ) if @next.elems;
    }

    #say [ $want, @combinations ].gist;
    return False unless @combinations.elems;
    return @combinations;
}

subtest {
    my @combinations = store( 25, [ 20, 15, 10, 5, 5 ] );
    is @combinations.elems, 4, "Correct number of combinations";
    is @combinations.sort, [
        [ 15, 10 ],
        [ 20,  5 ], # first 5
        [ 20,  5 ], # second 5
        [ 15,  5,  5 ],
    ].sort, "Correct combinations";

    my $min = @combinations.map({ .elems }).min;
    is $min, 2, "Minimum containers is two";
    is @combinations.grep({ .elems == $min }).elems, 3, "Three combinations";
}, "Test Containers";

#done-testing; exit;

my @combinations = store( 150, "17-input".IO.lines.map({ .Int }) );
is @combinations.elems, 1638, "Correct number of combinations";
my $min = @combinations.map({ .elems }).min;
is $min, 4, "Minimum containers is two";
is @combinations.grep({ .elems == $min }).elems, 17, "17 combinations";

done-testing;
