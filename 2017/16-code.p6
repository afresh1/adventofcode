#!perl6
use Test;

# --- Day 16: Permutation Promenade ---
#
# You come upon a very unusual sight; a group of programs here appear to be
# dancing.
#
# There are sixteen programs in total, named a through p. They start by
# standing in a line: a stands in position 0, b stands in position 1, and so on
# until p, which stands in position 15.
#
# The programs' dance consists of a sequence of dance moves:
#
#     Spin, written sX, makes X programs move from the end to the front, but
#     maintain their order otherwise. (For example, s3 on abcde produces
#     cdeab).
#
#     Exchange, written xA/B, makes the programs at positions A and B swap
#     places.
#
#     Partner, written pA/B, makes the programs named A and B swap places.

sub parse-moves(@moves) {
    @moves.map( {
        when /^s(\d+)$/                  { s => $/[0].Int };
        when /^x(\d+)\/(\d+)$/           { e => $/[0,1].map(*.Int).list };
        when /^p(<[a..z]>)\/(<[a..z]>)$/ { p => $/[0,1].map(*.Str).list };
        die "Unknown move '$_'";
    } );
}

class DanceHall {
    subset Dancer of Str where * ~~ ('a'..'z').any;
    has Dancer @!dancers;

    method new(Int $dancers = 16) {
        self.bless( :dancers( ('a' .. 'z' )[^$dancers] ) );
    }
    submethod BUILD(:@!dancers) {}

    method spin(Int $r)             { @!dancers = @!dancers.rotate(-$r) }
    method exchange(Int $i, Int $j) {
        # way, way faster
        # https://www.reddit.com/r/adventofcode/comments/7k572l/2017_day_16_solutions/drbro71/
        (@!dancers[$i], @!dancers[$j]) = (@!dancers[$j], @!dancers[$i])
    }
    method partner(Dancer $a, Dancer $b) {
        #my sub index-of($x) { @!dancers.pairs.first({ .value eq $x }, :k) }
        #self.exchange( index-of($a), index-of($b) );
        self.exchange( |@!dancers.grep( $a | $b, :k ) );
    }

    method step(Pair $move) {
        given $move {
            when .key eq 's' { self.spin(.value) }
            when .key eq 'e' { self.exchange(|.value) }
            when .key eq 'p' { self.partner(|.value) }
            default { die "Unknown move '$_'" }
        }
    }
    method dance(@moves) { self.step($_) for @moves; self }

    method Str  { self.gist }
    method gist { @!dancers.join }
}

# For example, with only five programs standing in a line (abcde), they could
# do the following dance:

{
    my @moves = parse-moves( < s1 x3/4 pe/b > );
    my $dance = DanceHall.new(5);
    is $dance, 'abcde', "Dancers start in appropriate positions";

    $dance.step(@moves[0]);
    is $dance, 'eabcd', "s1, a spin of size 1: eabcd.";
    $dance.step(@moves[1]);
    is $dance, 'eabdc', "x3/4, swapping the last two programs: eabdc.";
    $dance.step(@moves[2]);
    is $dance, 'baedc', "pe/b, swapping programs e and b: baedc.";

# After finishing their dance, the programs end up in order baedc.
    is DanceHall.new(5).dance(@moves), 'baedc',
        "Full dance ends up in order baedc";
}

# You watch the dance for a while and record their dance moves (your puzzle
# input). In what order are the programs standing after their dance?

my @moves = parse-moves( "16-input".IO.lines.first.split(',') );
my $dance = DanceHall.new;
my %seen = $dance => 0;
is $dance.dance(@moves), "olgejankfhbmpidc",
    "Dance with one round of input ends up as expected";
%seen{$dance} = 1;

# --- Part Two ---
#
# Now that you're starting to get a feel for the dance moves, you turn your
# attention to the dance as a whole.
#
# Keeping the positions they ended up in from their previous dance, the
# programs perform it again and again: including the first dance, a total of
# one billion (1000000000) times.
#
# In the example above, their second dance would begin with the order baedc,
# and use the same dance moves:
{
    my @moves = parse-moves( < s1 x3/4 pe/b > );
    my $dance = DanceHall.new(5);
    $dance.dance(@moves);

    is $dance, 'baedc', "After first round, expected position";

    $dance.step(@moves[0]);
    is $dance, 'cbaed', "s1, a spin of size 1: cbaed.";
    $dance.step(@moves[1]);
    is $dance, 'cbade', "x3/4, swapping the last two programs: cbade.";
    $dance.step(@moves[2]);
    is $dance, 'ceadb', "pe/b, swapping programs e and b: ceadb.";
}

# In what order are the programs standing after their billion dances?
{
    my $rounds = 1_000_000_000;

    $dance.dance(@moves);
    my $i = %seen.values.max + 1;

    while ( not %seen{$dance} ) {
        qq{# round $i.fmt('%3d'): $dance}.say;
        %seen{$dance} = $i;
        $dance.dance(@moves);
        $i++;
    }

    my $remaining = $rounds % ( $i - 1 );
    say "# ... $remaining = $rounds % ($i - 1)";
    # $dance = %seen.first({.value == $remaining}).key;
    is %seen.first({.value == $remaining}).key, "gfabehpdojkcimnl",
        "After 1 billion rounds, dancers are in correct position";
}

done-testing;
