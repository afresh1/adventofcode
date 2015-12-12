#!/usr/local/bin/perl6
use v6;
use Test;

sub validate-password (Str $pass) {
    my @p = $pass.split('', :skip-empty);

    my $consecutive;
    my $double;
    my %doubles;

    for @p.kv -> $i, $c {
        if < i o l >.first($c).defined { 
            return { valid => False, index => $i, character => $c };
        }

        if ($double and $c eq $double) {
            %doubles{$c} = True;
            $double      = False;
        }
        else {
            $double = $c;
        }

        unless ($consecutive) {
            if ( @p[ $i + 2 ]:exists
                and @p[ $i + 1 ] eq chr($c.ord + 1)
                and @p[ $i + 2 ] eq chr($c.ord + 2) ) {
                $consecutive = @p[ $i .. $i + 2 ].join('');
            }
        }
    }

    return { valid => True } if $consecutive and %doubles.elems >= 2;
    return {
        valid       => False,
        consecutive => $consecutive.Bool,
        doubles => %doubles,
    };
}

sub next-password (Str $old) {
    my $new = $old;
    $new++;

    while True {
        my %check = validate-password($new);
        last if %check<valid>;

        #say $new;
        #say %check;

        my $i;
        if %check<index> {
            $i := %check<index>;
        }
        elsif %check<doubles>.elems == 0 {
            $i = $new.chars - 3;
        }

        if ($i) {
            $new = $new.substr(0, $i + 1);
            $new++;
            $new ~= ('a' x ($old.chars - $i - 1));
        }
        else {
            $new++;
        }
        exit if $new.index('ghjaabd');
    }

    return $new;
}

nok validate-password('hijklmmn')<valid>,
    'meets the first requirement (because it contains the straight hij) but fails the second requirement requirement (because it contains i and l).';
nok validate-password('abbceffg')<valid>,
    'meets the third requirement (because it repeats bb and ff) but fails the first requirement.';
nok validate-password('abbcegjk')<valid>,
    'fails the third requirement, because it only has one double letter (bb).';

is next-password('abcdefgh'), 'abcdffaa', "Found next sample password";
is next-password('ghijklmn'), 'ghjaabcc',
    "because you eventually skip all the passwords that start with ghi..., since i is not allowed.";

is next-password('hxbxwxba'), 'hxbxxyzz', "First puzzle challenge";
is next-password('hxbxxyzz'), 'hxcaabcc', "Second puzzle challenge";

done-testing;
