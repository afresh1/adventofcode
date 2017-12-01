#!perl6
use Test;

sub uncaptcha(Str $s) returns Int {
    my @c = $s.split('', :skip-empty);
    my @i = @c.rotate(-1);
    return [+] map { $_[1] }, grep { @i[$^a] == $^b }, @c.kv;
}

is uncaptcha(    '1122'), 3, "Uncaptcha'd     1122 is 3";
is uncaptcha(    '1111'), 4, "Uncaptcha'd     1111 is 4";
is uncaptcha(    '1234'), 0, "Uncaptcha'd     1234 is 0";
is uncaptcha('91212129'), 9, "Uncaptcha'd 91212129 is 9";

say "Uncaptcha'd 1-input is: " ~ uncaptcha('1-input'.IO.slurp.chomp);

done-testing;
