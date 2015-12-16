#!/usr/local/bin/perl6
use v6;
use Test;

sub decode (Str $line) {
    my ($name, $properties) = $line.split(': ', 2);
    my %properties = $properties.split(/<[,:]> \s*/)
        .hash.kv.map( -> $k, $v { $k => $v.Int });

    return ( $name => %properties );
}

my %clues = (
    children    => 3,
    cats        => 7,
    samoyeds    => 2,
    pomeranians => 3,
    akitas      => 0,
    vizslas     => 0,
    goldfish    => 5,
    trees       => 3,
    cars        => 2,
    perfumes    => 1,
);

my %aunts = "16-input".IO.lines.map({ decode $_ }).hash;
for %aunts.kv -> $name, %stats {
    %stats<score> = 0;
    %stats<wrong_score> = 0;
    for %clues.kv -> $clue, $count {
        next unless %stats{$clue}:exists;
        %stats<wrong_score>++ if %stats{$clue} == $count;

        given $clue {
            when ( < cats trees >.first($clue) ) {
                %stats<score>++ if %stats{$clue} > $count;
            }
            when ( < pomeranians goldfish >.first($clue) ) {
                %stats<score>++ if %stats{$clue} < $count;
            }
            default { %stats<score>++ if %stats{$clue} == $count }
        }
    }
}

is %aunts.keys.reduce({
    %aunts{$^a}<wrong_score> > %aunts{$^b}<wrong_score> ?? $^a !! $^b;
}), 'Sue 40', "The wrong aunt is #40";

is %aunts.keys.reduce({
    %aunts{$^a}<score> > %aunts{$^b}<score> ?? $^a !! $^b;
}), 'Sue 241', "The right aunt is #241";

done-testing;
