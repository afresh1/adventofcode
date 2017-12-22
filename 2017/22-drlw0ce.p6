#!perl6

# https://www.reddit.com/r/adventofcode/comments/7lf943/2017_day_22_solutions/drlw0ce/
my @input = slurp.lines».comb;

my $size = 499;
my $half = $size div 2;
my @grid   = ('.' xx $size).Array xx $half - 12;
my @middle = ('.' xx $half - 12).Array xx 25;
my @end    = ('.' xx $size).Array xx $half - 12;

for ^25 -> $x {
    @middle[$x].append: |@input[$x];
    @middle[$x].append: ('.' xx $half - 12);
}

@grid.append: @middle;
@grid.append: @end;

my int $vx    = $half;
my int $vy    = $half;
my int $d     = 0;
my int $count = 0;

for ^10000000 {
    my $c = @grid[$vy][$vx];
    if $c eq '#' {
        $d = ($d + 1) % 4;
        @grid[$vy][$vx] = 'F';
    }
    elsif $c eq '.' {
        $d = ($d - 1) % 4;
        @grid[$vy][$vx] = 'W';
    }
    elsif $c eq 'F' {
        $d = ($d + 2) % 4;
        @grid[$vy][$vx] = '.';
    }
    elsif $c eq 'W' {
        @grid[$vy][$vx] = '#';
        $count++;
    }
    if    $d == 0 { $vy -= 1; }
    elsif $d == 1 { $vx += 1; }
    elsif $d == 2 { $vy += 1; }
    elsif $d == 3 { $vx -= 1; }
}
say "Part 2: {$count}"

