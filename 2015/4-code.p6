#!/usr/local/bin/perl6
use v6;
use Test;

fail "I didn't get it working, it was too slow";
done-testing;
exit;

sub md5(Str $str) {
    return run("md5", "-q", "-s", $str, :out).out.get;
}

sub find_coin(Str $str, Int $start = 1) {
    my $md5 = '';
    my $i = $start - 1;
    while (not $md5 ~~ /^0**5/) {
        $i++;
        $md5 = md5 "$str$i";
    }
    return $i;
}

my $str = "abcdef";
my @promises;
say "Starting...";
my @c = (0..7).map({ Channel.new });

for @c -> $c {
    start {
        my $closed = $c.closed;
        loop {
            if $c.poll -> $item {
                my $md5 = md5 "$str$item";
                #say "[$item] $md5";

                if ($md5 ~~ /^0**5/) {
                    $_.close for @c;
                }
            }
            elsif $closed {
                last;
            }
        }
    }
}

await (608500..609100).map: -> $r {
    my $c = @c[ $r % @c ];
    start { $c.send($r) unless $c.closed; }
}
$_.close for @c;
#for $c.list -> $r { say $r; }

#for (0..10) {
    #my $proc = Proc::Async.new("md5", "-q", "-s", "$str$_");
    #$proc.stdout.tap(-> $v { print "Output: $v" });
    #$proc.stderr.tap(-> $v { print "Error:  $v" });

    #@promises.push( $proc.start );
#}
#await @promises;
#say .result for @promises;
say "Done.";

pass;
done-testing;
exit;

is md5("abcdef609043"), "000001dbbfa3a5c83a2d506429c7b00e",
    "Expected MD5 for 'abcdef609043'";

is find_coin("abcdef", 609040), 609043, "Coin for 'abcdef' is 609043";
is find_coin("pqrstuv", 1048965), 1048970, "Coin for 'pqrstuv' is 1048970";

is find_coin("ckczppom"), 0, "Coin for 'ckczppom' is 0";

done-testing;
