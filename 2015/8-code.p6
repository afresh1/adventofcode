#!/usr/local/bin/perl6
use v6;
use Test;

sub decode (Str $s) {
    $_ = $s;
    s/^$<quote>=[^<['"]>]$<string>=(.*)$<quote>$/$<string>/;
    s:g/ \\ $<chr>=[ \\ | <['"]> | x<[0..9a..fA..F]>**2 ]/{
        my $c = $<chr>;
        $c ~~ /^x/ ?? "0$c".chr !!  $c
    }/;

    #say [ $s, $_ ];
    return [ $s.chars, $_.chars ];
}

sub encode (Str $s) {
    $_ = $s;
    s:g/ $<chr>=[<[\"\\]>] /\\$<chr>/;

    # How would I make this work?
    #my $d = $s.subst(/ $<chr>=[<[\"\\]>] /, "\\$/<chr>", :g);

    #say [ $s, $_ ];
    return [ $s.chars, qq{"$_"}.chars ];
}

subtest {
    is decode(q{""}), [2,0],
        q{"" is 2 characters of code (the two double quotes), but the string contains zero characters.};

    is decode(q{"abc"}), [5,3],
        q{"abc" is 5 characters of code, but 3 characters in the string data.};

    is decode(q{"aaa\"aaa"}), [10,7],
        q{"aaa\"aaa" is 10 characters of code, but the string itself contains six "a" characters and a single, escaped quote character, for a total of 7 characters in the string data.};

    is decode(q{"\x27"}), [6,1],
        q{"\x27" is 6 characters of code, but the string itself contains just one - an apostrophe ('), escaped using hexadecimal notation.};


    my @counts = (0,0);
    for "8-input".IO.lines.map({ decode($_) }) -> $l {
        @counts[$_] += $l[$_] for 0, 1;
    }
    #say [ @counts, @counts.reduce(&[-]) ];
    is @counts, [ 6202, 4860 ], "Correct number of decoded characters in input";
}, "Decode";

subtest {
    is encode(q{""}), [2,6],
        q{"" encodes to "\"\"", an increase from 2 characters to 6.};

    is encode(q{"abc"}), [5,9],
        q{"abc" encodes to "\"abc\"", an increase from 5 characters to 9.};

    is encode(q{"aaa\"aaa"}), [10,16],
        q{"aaa\"aaa" encodes to "\"aaa\\\"aaa\"", an increase from 10 characters to 16.};

    is encode(q{"\x27"}), [6,11],
        q{"\x27" encodes to "\"\\x27\"", an increase from 6 characters to 11.};


    my @counts = (0,0);
    for "8-input".IO.lines.map({ encode($_) }) -> $l {
        @counts[$_] += $l[$_] for 0, 1;
    }
    #say [ @counts, @counts.reduce(&[-]) ];
    is @counts, [ 6202, 8276 ], "Correct number of encoded characters in input";
}, "Encode";

done-testing;
