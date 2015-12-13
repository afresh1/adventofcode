#!/usr/local/bin/perl6
use v6;
use Test;

sub sum-digits (Str $json) {
    [+] [ $json ~~ m:g/(\-?\d+)/ ].map({ .Int });
}

sub clean (Str $json) {
    my @json = $json.split("");

    my @brackets;

    for @json.kv -> $i, $c {
        given $c {
            when ('{') { push @brackets, { start => $i, bracket => $c } }
            when ('[') { push @brackets, { start => $i, bracket => $c } }

            when ('}') {
                my $set = pop @brackets;
                die "Something went wrong" unless $set<bracket> eq '{';
                if $set<remove> {
                    my $start = $set<start> + 1;
                    my $end   = $i - 1;
                    @json[$_] = Nil for $start .. $end;
                }
            }

            when (']') {
                my $set = pop @brackets;
                die "Something went wrong" unless $set<bracket> eq '[';
            }

            when ('"') {
                if @brackets.elems {
                    my $bracket := @brackets[*-1];
                    if $bracket<bracket> eq '{'
                        and @json[$i..$i+4].join eq q{"red"} {
                        $bracket<remove> = True;
                    }
                }
            }
        }
    }

    return @json.grep({ .defined }).join;
}



sub sum-sub-digits (Str $json) {
    my $clean = clean($json);
    return sum-digits($clean);
}

is sum-digits('[1,2,3]'), 6;
is sum-digits('{"a":2,"b":4}'), 6; # both have a sum of 6.
is sum-digits('[[[3]]]'), 3;
is sum-digits('{"a":{"b":4},"c":-1}'), 3; # both have a sum of 3.
is sum-digits('{"a":[-1,1]}'), 0;
is sum-digits('[-1,{"a":1}]'), 0; # both have a sum of 0.
is sum-digits('[]'), 0;
is sum-digits('{}'), 0; # both have a sum of 0.

is sum-digits('12-input'.IO.slurp), 119433;

is sum-sub-digits('[1,2,3]'), 6;
is sum-sub-digits('{"a":2,"b":4}'), 6; # both have a sum of 6.
is sum-sub-digits('[[[3]]]'), 3;
is sum-sub-digits('{"a":{"b":4},"c":-1}'), 3; # both have a sum of 3.
is sum-sub-digits('{"a":[-1,1]}'), 0;
is sum-sub-digits('[-1,{"a":1}]'), 0; # both have a sum of 0.
is sum-sub-digits('[]'), 0;
is sum-sub-digits('{}'), 0; # both have a sum of 0.

is sum-sub-digits('[1,{"c":"red","b":2},3]'), 4; # now has a sum of 4, because the middle object is ignored.

is sum-sub-digits('[1,{"c":"red","b":2},{"red":3, "blue": {"green":4}},3]'), 4; # now has a sum of 4, because the middle object is ignored.
#done-testing; exit;
is sum-sub-digits('{"d":"red","e":[1,2,3,4],"f":5}'), 0; # now has a sum of 0, because the entire structure is ignored.
is sum-sub-digits('[1,"red",5]'), 6; # has a sum of 6, because "red" in an array has no effect.

is sum-sub-digits('12-input'.IO.slurp), 68466; # too low
done-testing;
