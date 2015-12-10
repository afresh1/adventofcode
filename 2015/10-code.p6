#!/usr/local/bin/perl6
use v6;
use Test;

sub look-and-say (Str $_) {
    my $num   = 0;
    my $index = 0;

    return .split('', :skip-empty).kv.map( -> $i, $d {
        if ($num != $d) {
            my $ret = $num ?? ($i - $index) ~ $num !! '';
            $num = $d;
            $index = $i;
            $ret;
        }
        else { '' }
    }).join('') ~ ( .chars - $index ) ~ $num;

#    return m:g/$<str>=[$<num>=[\d]$<num>*]/
#        .map({ $_<str>.chars ~ $_<num> }).join;
}

is look-and-say('1'), 11, "(1 copy of digit 1).";
is look-and-say('11'), 21, "(2 copies of digit 1).";
is look-and-say('21'), 1211, "(one 2 followed by one 1).";
is look-and-say('1211'), 111221, "(one 1, one 2, and two 1s).";
is look-and-say('111221'), 312211, "(three 1s, two 2s, and one 1).";

#done-testing; exit;

my $input = '1321131112';
for 0..39 {
    diag "$_: " ~ $input.chars;
    $input = look-and-say($input);
}

is $input.chars, 492982, "After 40 iterations, length is 492,982";
spurt "10-output-40", "$input\n";

for 40..49 {
    diag "$_: " ~ $input.chars;
    $input = look-and-say($input);
}

is $input.chars, 0, "After 50 iterations, length is 0";
spurt "10-output-50", "$input\n";

done-testing;
