#!/usr/local/bin/perl6
use v6;
use Test;

sub make-sacks ($weight, @packages, @have = []) {
    my @sacks;
    for @packages -> $w {
        next if @have.elems and $w <= @have[*-1];

        my @sack = |@have, $w;
        if $w < $weight {
            @sacks.append( make-sacks( $weight - $w, @packages, @sack ) )
                if $weight - $w > $w; # No need to check if none will fit
        }
        elsif $w == $weight {
            @sacks.push(@sack);
            @sack.say;
        }
        else { last }
    }

    return @sacks;
}

sub combinations-of (@sacks) {
    my @two;
    my @c-bags;
    for @sacks -> $first {
        for @sacks -> $second {
            next if ($first ∩ $second).elems;
            my @t = $first, $second;
            if bag(@t) ∉ @c-bags {
                @two.push( @t );
                @c-bags.push(bag(@t));
            }
        }
    }

    my @combinations;
    @c-bags = [];
    for @two -> $t {
        my $b = [$t.map({ .values }).flat];
        for @sacks -> @third {
            next if ($b ∩ @third).elems;
            my @c = |$t, @third;
            if bag(@c) ∉ @c-bags {
                @combinations.push( @c );
                @c-bags.push( bag(@c) );
                @c.say;
            }
        }
    }
    return @combinations;
}

sub split-packages (@packages) {
    my $weight = @packages.reduce(&[+]) / 3;
    say [ @packages, $weight ].perl;
    my @sacks = make-sacks($weight, @packages.sort);
    return combinations-of(@sacks.sort({ $^a.elems <=> $^b.elems }));
}

sub best-sack (@combinations) {
    my $best-sack;
    for @combinations.map({$_[0]}).unique -> $sack {
        last if $best-sack and $sack.elems > $best-sack.elems;
        $best-sack ||= $sack;
        $best-sack = $sack if $best-sack.reduce(&[*]) > $sack.reduce(&[*]);
    }
    return $best-sack;
}

sub estimate-best-sack (
    @packages,
    $count      = 3,
    $weight     = @packages.reduce(&[+]) / $count,
    $first-sack = True,
    @have       = [],
    $remaining  = $weight,
) {
    return unless @packages.elems;
    return if $remaining > [+] @packages;

    my $best = Inf;
    my @sacks;
    for @packages -> $w {
        # We know it won't work due to having sorted input
        next if @have and @have[*-1] <= $w;

        my @sack = |@have, $w;
        my @remaining = @packages.grep({ $_ ∉ @sack }).sort.reverse;

        my $b;
        if $w < $remaining {
            # No need to check further if we already have a better solution
            last if @sack.elems + 1 > $best;

            my @s = estimate-best-sack(
                @remaining, $count, $weight, $first-sack,
                @sack, $remaining - $w
            );

            if @s.elems {
                @sacks.append( @s );
                $b = @s.map({ .elems }).min;
            }
        }
        elsif $w == $remaining {
            if @remaining.elems {
                my $sub-sacks = estimate-best-sack(
                    @remaining, $count - 1, $weight, False );

                if $sub-sacks.elems {
                    @sacks.push( @sack );
                    $b = @sack.elems;
                }
            }
            else {
                @sacks.push( @sack );
                $b = @sack.elems;
            }
        }

[   $count,
    [ $best, $b ],
    [$weight, $remaining],
    #[@sack.elems, '>', $best],
    $first-sack,
    @sacks,
    #@sack, @remaining
].say if @sacks.elems;

        # We only care that a solution exists, not how many
        last if not $first-sack and @sacks.elems;

        $best = $b if $b and $best > $b;
    }

    return @sacks;
}

sub estimate-best (@packages, $count = 3) {
    my @sacks = estimate-best-sack( @packages, $count );

    my $best;
    for @sacks.sort({ $^a.elems <=> $^b.elems }) {
        if $best {
            $best = $_ if $best.elems == .elems
                and $best.reduce(&[*]) > .reduce(&[*]);
        }
        else {
            $best = $_;
        }
        [ $_, $best ].say;
    }
    return $best;
}

subtest {
    my @packages = [(7..11, 1..5).flat];
#    my @combinations = split-packages(@packages);
#    my $best = best-sack( @combinations );
#    is $best, [9, 11], "Correct smallest package";
#    is $best.reduce(&[*]), 99, "Correct entaglement";
    is estimate-best(@packages.sort.reverse), [11, 9],
        "Estimated best is the same";
}, "Sample Packages";

subtest {
    my @packages = [(7..11, 1..5).flat];
    is estimate-best(@packages.sort.reverse, 4), [11, 4],
        "Estimated best is the same";
}, "Sample Packages";

#done-testing; exit;

subtest {
    my @packages = "24-input".IO.lines.map({ .Int });

#    my @combinations = split-packages(@packages);
#    my $best = best-sack( @combinations );
#    is $best, [], "Correct smallest package";
#    is $best.reduce(&[*]), 0, "Correct entaglement";

    my $estimated = estimate-best(@packages.sort.reverse);
    is $estimated, [113, 109, 107, 103, 83, 1],
        "Estimated best correct";

    is $estimated.reduce(&[*]), 11266889531, "Expected quantum entanglement";
}, "Real Packages in three sacks";


subtest {
    my @packages = "24-input".IO.lines.map({ .Int });

    my $estimated = estimate-best(@packages.sort.reverse, 4);
    is $estimated, [113, 109, 107, 53, 5],
        "Estimated best correct";

    is $estimated.reduce(&[*]), 77387711, "Expected quantum entanglement";
}, "Real Packages in three sacks";
done-testing;
