#!/usr/local/bin/perl6
use v6;
use Test;

sub combine (Str $start, @replacements) {
    my @molecules;

    for @replacements {
        my ($f, $t) = .kv;
        for 0..$start.chars -> $i {
            if $start.substr-eq($f, $i) {
                my $molecule = $start;
                $molecule.substr-rw($i, $f.chars) = $t;
                @molecules.push($molecule);
            }
        }
    }

    return @molecules;
}

subtest {
    my @replacements = (
        { H => 'HO' },
        { H => 'OH' },
        { O => 'HH' },
    );

    # Given the replacements above and starting with HOH,
    # the following molecules could be generated:
    my @result = (
        'HOOH', # (via H => HO on the first H).
        'HOHO', # (via H => HO on the second H).
        'OHOH', # (via H => OH on the first H).
        'HOOH', # (via H => OH on the second H).
        'HHHH', # (via O => HH).
    );

    my @r = combine( 'HOH', @replacements );
    is @r, @result, "Expected molecules built";
    is @r.unique.elems, 4, "Four unique molecules";
}, "Test Combinations";

subtest {
    my @replacements = (
        { e => 'H' },
        { e => 'O' },
        { H => 'HO' },
        { H => 'OH' },
        { O => 'HH' },
    );

    my @molecules = ['e'];
    my $count = 0;
    while True {
        $count++;
        @molecules = @molecules.map({ combine($_, @replacements) }).flat.unique;
        last if 'HOHOHO' ∈ @molecules;
    }
    is $count, 6;
}, "Find Test Molecule";

my $molecule;
my @replacements;
for "19-input".IO.lines {
    when /^ $<f>=[\w+] \s+ \=\> \s+ $<t>=[\w+] $/ {
        @replacements.push({ $/<f> => $/<t>.Str });
    }
    default { $molecule = $_ }
}

subtest {
    my @r = combine( $molecule, @replacements );
    is @r.unique.elems, 518, "Unique molecules";
}, "Real First Combinations";

#subtest {
#    my @molecules = ['e'];
#    my $count = 0;
#    while True {
#        $count++;
#        diag "Step $count";
#        @molecules = @molecules.race # multithreaded!
#            .map({ combine($_, @replacements) }).flat.unique;
#        last if $molecule ∈ @molecules;
#    }
#    is $count, 6;
#}, "Find molecule by brute force";

subtest {
    my $m = $molecule;
    my $count = 0;
    while ($m ne 'e') {
        for @replacements {
            my ($f, $t) = .kv;
            my $match = $m ~~ s:g/$t/$f/;
            $count += $match.elems;
            #diag "Step $count" if $match.elems;
        }
    }
    is $count, 200, "200 steps to reverse";
}, "Reverse Molecule";

done-testing;
