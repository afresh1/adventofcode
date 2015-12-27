#./usr/local/bin/perl6
use v6;
use Test;

class CodeGenerator does Iterator {
    has UInt $.row;
    has UInt $.col;
    has UInt $.value;

    my $mul =    252_533;
    my $mod = 33_554_393;

    my $filename = "25-codebook";
    has $!fh;
    has @.fh-best;

    submethod BUILD (:$!row, :$!col, :$!value, :$!fh, :@!fh-best) {}
    multi method new ($row = 1, $col = 1) {
        my %start = row => 1, col => 1, value => 20151125;
        my @fh-best = 0, 0;

        my $level = $row + $col;

        if $filename.IO.e {
            my $fh = open($filename);
            for $fh.lines -> $line {
                my ($r, $c, $v) = $line.split(/\s+/).map({ .Int });
                @fh-best = $r, $c;

                my $this-level = $r + $c;
                next if $this-level > $level; # just look for the last item

                %start = row => $r, col => $c, value => $v
                    if $this-level < $level or $c <= $col;
            }
        }

        my $fh = open($filename, :a);
        $fh.seek(0, SeekFromEnd);

        my $s = self.bless(
            :row(%start<row>),
            :col(%start<col>),
            :value(%start<value>),
            :$fh,
            :fh-best(@fh-best),
        );

        $s.pull-one while $s.level < $level;
        $s.pull-one while $s.col   < $col;

        return $s;
    }

    method level () { $.row + $.col }

    method pull-one () {
        if $.row === 1 {
            $!row = $.col + 1;
            $!col = 1;
        }
        else {
            $!col++;
            $!row--;
        }

        $!value = $.value * $mul mod $mod;

        if $!fh.e {
            my $best-level = [+] @!fh-best;
            if $best-level < self.level
                or ( $best-level == self.level and @!fh-best[1] < $.col) {

                $!fh.print("$.row $.col $.value\n");
                @!fh-best = $.row, $.col;
            }
        }

        return $.value;
    }

}

sub parse ($str) {
    my @table;

    for $str.lines -> $line {
        my ($r, $vals) = $line.split('|').map({ .trim });
        next unless $r and $vals;
        @table[$r] = Nil, |$vals.split(/\s+/);
    }

    return @table;
}

my @table = parse(q{
   |    1         2         3         4         5         6
---+---------+---------+---------+---------+---------+---------+
 1 | 20151125  18749137  17289845  30943339  10071777  33511524
 2 | 31916031  21629792  16929656   7726640  15514188   4041754
 3 | 16080970   8057251   1601130   7981243  11661866  16474243
 4 | 24592653  32451966  21345942   9380097  10600672  31527494
 5 |    77061  17552253  28094349   6899651   9250759  31663883
 6 | 33071741   6796745  25397450  24659492   1534922  27995004
});

subtest {
    my $cg = CodeGenerator.new;
    my $row := $cg.row;
    my $col := $cg.col;
    while @table[ $cg.row ][ $cg.col ] -> $expect {
        is $cg.value, $expect, "[$row][$col] is $expect";
        $cg.pull-one;
    }
}, "Table Results";

subtest {
    my $cwd = ".".IO.absolute;
    my $test-dir = "test-dir".IO;
    $test-dir.mkdir;
    chdir $test-dir;
    my $codebook ="25-codebook".IO;
    $codebook.unlink;

    is CodeGenerator.new.fh-best, [0,0], "Best starts at 0,0";
    is CodeGenerator.new( 2, 2 ).value, 21629792, 'Looked up 2,2 properly';
    is CodeGenerator.new.fh-best, [2,2], "Best is now 2,2";
    is CodeGenerator.new( 3, 4 ).value, 7981243, 'Looked up 3,4 properly';
    is CodeGenerator.new.fh-best, [3,4], "Best is now 3,4";

    $codebook.unlink;
    chdir $cwd;

    $test-dir.rmdir;
}, "New with specific row";

#is CodeGenerator.new( 3010, 3019 ).value, 8997277,
#    "row 3010 column 3019 has expected value";

# I knew there was a mathy way to do this, but my lack of CS background
# has failed me yet again in these Advent of Code challenges.
# Really though, I wanted to write an Iterator object and even more importantly
# I think I learned a lot about constructing perl6 classes.
subtest {
    my $row = 3010;
    my $col = 3019;
    my $start = 20151125;

    my $mul =    252_533;
    my $mod = 33_554_393;

    my $exp = ($row + $col - 2) * ($row + $col - 1) div 2 + $col - 1;
    my $ans = $mul.expmod($exp, $mod) * $start mod $mod;
    is $ans, 8997277, "Correct answer with expmod";
}, "Exponential Modulus";

done-testing;
