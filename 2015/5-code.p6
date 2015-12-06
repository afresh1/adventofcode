#!/usr/local/bin/perl6
use v6;
use Test;

subtest {
    sub naughty(Str $string) {
        my $naughty = False;

        given $string {
            when m:global/<[aeiou]>/.elems < 3 {
                $naughty = 'Less than three vowels';
            }
            when not /$<l>=[.]$<l>/ { $naughty = 'No double letter' }
            when /$<bad>=(ab|cd|pq|xy)/ { $naughty = "Has string $<bad>" }
        }

        return $naughty;
    }

    is naughty("ugknbfddgicrmopn"), False,
    "ugknbfddgicrmopn is nice because it has at least three vowels (u...i...o...), a double letter (...dd...), and none of the disallowed substrings.";
    is naughty("aaa"), False,
    "aaa is nice because it has at least three vowels and a double letter, even though the letters used by different rules overlap.";
    is naughty("jchzalrnumimnmhp"), 'No double letter',
    "jchzalrnumimnmhp is naughty because it has no double letter.";
    is naughty("haegwjzuvuyypxyu"), 'Has string xy',
    "haegwjzuvuyypxyu is naughty because it contains the string xy.";
    is naughty("dvszwmarrgswjxmb"), 'Less than three vowels',
    "dvszwmarrgswjxmb is naughty because it contains only one vowel.";

    my $nice = "5-input".IO.lines.grep({ not naughty($_) }).elems;
    is $nice, 236, "236 nice lines in the file";
}, "Original list";

subtest {
    sub naughty(Str $string) {
        my $naughty = False;
        
        given $string {
            when not /$<pair>=[..].*$<pair>/ { $naughty = 'No double pair' }
            when not /$<l>=[.].$<l>/ { $naughty = 'No repeats' }
        }

        return $naughty;
    }

    is naughty("qjhvhtzxzqqjkmpb"),  False,
        "qjhvhtzxzqqjkmpb is nice because is has a pair that appears twice (qj) and a letter that repeats with exactly one letter between them (zxz).";
    is naughty("xxyxx"), False,
        "xxyxx is nice because it has a pair that appears twice and a letter that repeats with one between, even though the letters used by each rule overlap.";
    is naughty("uurcxstgmygtbstg"), "No repeats",
        "uurcxstgmygtbstg is naughty because it has a pair (tg) but no repeat with a single letter between them.";
    is naughty("ieodomkazucvgmuy"), "No double pair",
        "ieodomkazucvgmuy is naughty because it has a repeating letter with one between (odo), but no pair that appears twice.";

    my $nice = "5-input".IO.lines.grep({ not naughty($_) }).elems;
    is $nice, 51, "51 nice lines in the file";
}, "Second try";

done-testing;
