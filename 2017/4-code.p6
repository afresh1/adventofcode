#!perl6
use Test;

# --- Day 4: High-Entropy Passphrases ---
#
# A new system policy has been put in place that requires all accounts to use a
# passphrase instead of simply a password. A passphrase consists of a series of
# words (lowercase letters) separated by spaces.

sub password-policy1(Str $password) {
    my @words = $password.comb(/\w+/);
    my %seen;
    for (@words) { return False if %seen{$_}++ }
    return True;
}

# To ensure security, a valid passphrase must contain no duplicate words.
#
# For example:

ok password-policy1("aa bb cc dd ee"),
     "aa bb cc dd ee is valid.";
ok !password-policy1("aa bb cc dd aa"),
     "aa bb cc dd aa is not valid - the word aa appears more than once.";
ok password-policy1("aa bb cc dd aaa"),
     "aa bb cc dd aaa is valid - aa and aaa count as different words.";

# The system's full passphrase list is available as your puzzle input.
# How many passphrases are valid?

{
    my $count = 0;
    for "4-input".IO.lines {
        $count++ if password-policy1($_);
    }
    say "There are $count valid passwords in the input file under policy 1";
}

# --- Part Two ---
#
# For added security, yet another system policy has been put in place. Now, a
# valid passphrase must contain no two words that are anagrams of each other -
# that is, a passphrase is invalid if any word's letters can be rearranged to
# form any other word in the passphrase.

sub password-policy2(Str $password) {
    my @words = $password.comb(/\w+/);
    my %seen;
    for (@words) { return False if %seen{$_.comb.sort.join}++ }
    return True;
}

# For example:

ok password-policy2("abcde fghij"),
     "abcde fghij is a valid passphrase.";
ok !password-policy2("abcde xyz ecdab"),
     "abcde xyz ecdab is not valid - the letters from the third word can be rearranged to form the first word.";
ok password-policy2("a ab abc abd abf abj"),
     "a ab abc abd abf abj is a valid passphrase, because all letters need to be used when forming another word.";
ok password-policy2("iiii oiii ooii oooi oooo"),
     "iiii oiii ooii oooi oooo is valid.";
ok !password-policy2("oiii ioii iioi iiio");
     "oiii ioii iioi iiio is not valid - any of these words can be rearranged to form any other word.";

# Under this new system policy, how many passphrases are valid?

{
    my $count = 0;
    for "4-input".IO.lines {
        $count++ if password-policy2($_);
    }
    say "There are $count valid passwords in the input file under policy 2";
}

done-testing;
