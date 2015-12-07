#!/usr/local/bin/perl6
use v6;
use Test;

sub md5(Str $str) {
    return run("md5", "-q", "-s", $str, :out).out.get;
}

sub find_coin(Str $str, Int $count = 5, Int $start = 1) {
    my $c = Channel.new;
    my $p = start {
        my $closed = $c.closed;
        my $md5;
        loop {
            if $c.poll -> $item {
                $md5 ||= $item;
            }
            elsif $closed {
                last;
            }
        }
        $md5;
    }

    my $zeros = 0 x $count;

    for [$start..*] -> $r {
        last if $c.closed;
        start {
            my $m = md5 "$str$r";
            if ($m.substr-eq($zeros, 0)) {
                my $md5 = qq{MD5 ("$str$r") = } ~ chomp $m;
                $c.send($md5);
                $c.close;
                last;
            }
        }
    }

    return $p.result;
}

is md5("abcdef609043"), "000001dbbfa3a5c83a2d506429c7b00e",
    "Expected MD5 for 'abcdef609043'";

is find_coin("pqrstuv", 5, 1048965),
    'MD5 ("pqrstuv1048970") = 000006136ef2ff3b291c85725f17325c';

is find_coin("ckczppom", 5, 117940),
    'MD5 ("ckczppom117946") = 00000fe1c139a2c710e9a5c03ec1af03';

is find_coin("ckczppom", 6, 3938030),
    'MD5 ("ckczppom3938038") = 00000028023e3b4729684757f8dc3fbf';

done-testing;
