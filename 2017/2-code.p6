#!perl6
use Test;

sub checksum(Str $sheet) {
    my @sheet = $sheet.split(/\n/).grep({$_}).map({ .comb(/\d+/).map({.Int}).Array });
    return @sheet.map({ .max - .min }).sum;
}

is checksum(q{
5 1 9 5
7 5 3
2 4 6 8
}), 18, q{
    The first row's largest and smallest values are 9 and 1, and their difference is 8.
    The second row's largest and smallest values are 7 and 3, and their difference is 4.
    The third row's difference is 6.
In this example, the spreadsheet's checksum would be 8 + 4 + 6 = 18.
};

say "Checksum for 2-input is: " ~ checksum("2-input".IO.slurp);

sub even_checksum(Str $sheet) {
    my @sheet = $sheet.split(/\n/).grep({$_}).map({ .comb(/\d+/).map({.Int}).Array });
    return @sheet.map({ .combinations(2).grep({ .max % .min == 0 }).map({ .max / .min }) }).flat.sum;
}

is even_checksum(q{
5 9 2 8
9 4 7 3
3 8 6 5
}), 9, q{
    In the first row, the only two numbers that evenly divide are 8 and 2; the result of this division is 4.
    In the second row, the two numbers are 9 and 3; the result is 3.
    In the third row, the result is 2.

In this example, the sum of the results would be 4 + 3 + 2 = 9.};

say "Even Checksum for 2-input is: " ~ even_checksum("2-input".IO.slurp);

done-testing;
