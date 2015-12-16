#!/usr/local/bin/perl6
use v6;
use Test;

sub parse-rule (Str $rule) {
    $rule.match(/
        ^
        $<recipient>=[\w+]
        .*
        $<direction>=[gain|lose] \s+ $<points>=[\d+]
        .*?
        $<giver>=[\w+]
        \.
        $
    /);

    my $points = $/<points>.Int;
    $points = 0 - $points if $/<direction> eq 'lose';

    return {
        giver     => $/<giver>.Str,
        recipient => $/<recipient>.Str,
        points    => $points,
    };
}

sub parse-rules (@rules) {
    my %rules;

    for @rules.map({ parse-rule($_) }) -> $r {
        %rules{$r<recipient>}{$r<giver>} = $r<points>;
    }

    return %rules;
}

sub find-costs (%rules) {
    my %costs;
    for %rules.keys.permutations
        .grep({ not %costs{ $_.reverse.join(" <> ") }:exists }) -> @r {

        my $cost = [+] @r.keys.map( -> $i {
            my $j = ( $i + 1 ) % @r.elems;
            my ($r, $g) = @r[$i, $j];
            ( %rules{$r}{$g} || 0 ) + ( %rules{$g}{$r} || 0 );
        });

        #say [ @r, $cost ];
        %costs{ @r.join(" <> ") } = $cost;
    }

    return %costs;
}

sub find-optimal-cost (%rules) {
    %rules.keys.permutations.map( -> @r {
        [+] @r.keys.map( -> $i {
            my ($r, $g) = @r[$i, ( $i + 1 ) % @r.elems];
            ( %rules{$r}{$g} || 0 ) + ( %rules{$g}{$r} || 0 );
        });
    }).max;
}

# implementation detail, `%r<Me> = {}` is all that is necessary
sub add-me (%rules) {
    my %r = %rules;
    %r{$_}{'Me'} = %r{'Me'}{$_} = 0 for %r.keys;
    return %r;
}

my @rules = (
    'Alice would gain 54 happiness units by sitting next to Bob.',
    'Alice would lose 79 happiness units by sitting next to Carol.',
    'Alice would lose 2 happiness units by sitting next to David.',
    'Bob would gain 83 happiness units by sitting next to Alice.',
    'Bob would lose 7 happiness units by sitting next to Carol.',
    'Bob would lose 63 happiness units by sitting next to David.',
    'Carol would lose 62 happiness units by sitting next to Alice.',
    'Carol would gain 60 happiness units by sitting next to Bob.',
    'Carol would gain 55 happiness units by sitting next to David.',
    'David would gain 46 happiness units by sitting next to Alice.',
    'David would lose 7 happiness units by sitting next to Bob.',
    'David would gain 41 happiness units by sitting next to Carol.',
);

is-deeply parse-rule(@rules[0]),
    { giver => 'Bob', recipient => 'Alice', points => 54};
is-deeply parse-rule(@rules[1]),
    { giver => 'Carol', recipient => 'Alice', points => -79 };

is-deeply parse-rules(@rules), {
    :Alice(${:Bob(54),    :Carol(-79), :David(-2)}),
    :Bob(  ${:Alice(83),  :Carol(-7),  :David(-63)}),
    :Carol(${:Alice(-62), :Bob(60),    :David(55)}),
    :David(${:Alice(46),  :Bob(-7),    :Carol(41)}),
};

is find-optimal-cost( parse-rules(@rules) ), 330,
    "Total happiness change 330 points";

is find-optimal-cost( add-me( parse-rules( @rules ) ) ), 286,
    "Total happiness change 286 points";

#is find-optimal-cost( parse-rules( "13-input".IO.lines ) ), 733;
#is find-optimal-cost( add-me( parse-rules( "13-input".IO.lines ) ) ), 725;

done-testing;
