#!/usr/bin/perl
use strict;
use warnings;

use 5.024;
use feature 'signatures';

use Test::More;

sub next_a ($current) { ( $current * 16807 ) % 2147483647 }
sub next_b ($current) { ( $current * 48271 ) % 2147483647 }

sub next_values( @current ) {
    return ( next_a($current[0]), next_b($current[1]) );
}

sub next_values_limited (@current) {
    my ($next_a, $next_b) = next_values(@current);

    $next_a = next_a( $next_a ) while $next_a % 4;
    $next_b = next_b( $next_b ) while $next_b % 8;

    return ( $next_a, $next_b );
}

# Generator A starts with 634
# Generator B starts with 301

# Test code
my @start = ( 65, 8921 ); # 588

{
    my $matches = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 5 ; $i++ ) {
        @v = next_values(@v);
        say "$i: @v" if $i % 100_000 == 0;
	#printf "$i %016b\n", $_ & 2**16-1 for @v;
        $matches++
            if ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**17-1 ) );
    }
    is $matches, 1, "Only one pair in the first 5 elments";
}

if (0) {
    my $matches = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 40_000_000 ; $i++ ) {
        @v = next_values(@v);
        say "$i: @v" if $i % 100_000 == 0;
        $matches++
            if ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**16-1 ) );
    }
    is $matches, 588, "So many matching pairs";
}

{
    my $matched = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 5_000_000 ; $i++ ) {
        @v = next_values_limited(@v);
	#printf "$i %12d %016b\n", $_, $_ & 2**16-1 for @v;
        say "$i: @v" if $i % 100_000 == 0;
        if ( ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**16-1 ) ) ) {
            $matched = $i;
            last;
        }
    }
    is $matched, 1056, "First match at 1056";
}

if (0) {
    my $matches = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 5_000_000 ; $i++ ) {
        @v = next_values_limited(@v);
	#printf "$i %12d %016b\n", $_, $_ & 2**16-1 for @v;
        say "$i: @v" if $i % 100_000 == 0;
        $matches++
            if ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**16-1 ) );
    }
    is $matches, 309, "So many even matching pairs";
}

@start = ( 634, 301 );

if (0) {
    my $matches = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 40_000_000 ; $i++ ) {
        @v = next_values(@v);
        say "$i: @v" if $i % 100_000 == 0;
        $matches++
            if ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**16-1 ) );
    }
    is $matches, 573, "So many matching pairs";
}

{
    my $matches = 0;
    my @v = @start;
    for ( my $i = 1; $i <= 5_000_000 ; $i++ ) {
        @v = next_values_limited(@v);
	#printf "$i %12d %016b\n", $_, $_ & 2**16-1 for @v;
        say "$i: @v" if $i % 100_000 == 0;
        $matches++
            if ( $v[0] & ( 2**16-1 ) ) == ( $v[1] & ( 2**16-1 ) );
    }
    is $matches, 294, "So many even matching pairs";
}

done_testing;
