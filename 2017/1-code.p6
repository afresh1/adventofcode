#!perl6
use Test;

sub uncaptcha(Str $s, Int $rot = Int($s.chars/2)) returns Int {
    my @c = $s.split('', :skip-empty);
    my @i = @c.rotate(-$rot);
    return [+] map { $_[1] }, grep { @i[$^a] == $^b }, @c.kv;
}

is uncaptcha(    '1122', 1), 3, "Uncaptcha'd     1122 is 3";
is uncaptcha(    '1111', 1), 4, "Uncaptcha'd     1111 is 4";
is uncaptcha(    '1234', 1), 0, "Uncaptcha'd     1234 is 0";
is uncaptcha('91212129', 1), 9, "Uncaptcha'd 91212129 is 9";

say "Uncaptcha'd 1-input is: " ~ uncaptcha('1-input'.IO.slurp.chomp, 1);

is uncaptcha('1212'), 6,
    "1212 produces 6: the list contains 4 items, and all four digits match the digit 2 items ahead.";
is uncaptcha('1221'), 0,
    "1221 produces 0, because every comparison is between a 1 and a 2.";
is uncaptcha('123425'), 4,
    "123425 produces 4, because both 2s match each other, but no other digit has a match.";
is uncaptcha('123123'),   12, "123123 produces 12.";
is uncaptcha('12131415'), 4,  "12131415 produces 4.";

say "Unrot'd 1-input is: " ~ uncaptcha('1-input'.IO.slurp.chomp);

done-testing;
