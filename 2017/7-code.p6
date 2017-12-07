#!perl6
use Test;

# --- Day 7: Recursive Circus ---
#
# Wandering further through the circuits of the computer, you come upon a tower
# of programs that have gotten themselves into a bit of trouble. A recursive
# algorithm has gotten out of hand, and now they're balanced precariously in a
# large tower.
#
# One program at the bottom supports the entire tower. It's holding a large
# disc, and on the disc are balanced several more sub-towers. At the bottom of
# these sub-towers, standing on the bottom disc, are other programs, each
# holding their own disc, and so on. At the very tops of these
# sub-sub-sub-...-towers, many programs stand simply keeping the disc below
# them balanced but with no disc of their own.

sub parse-discs(@lines) {
	@lines.grep({$_}).map({
		m{
			^        (\w+)
			\s+   \( (\d+) \)
		   [\s+ \-\> \s+ (.*)   ]?
			$
		};

		{ id => $/[0].Str, weight => $/[1].Int, tower => [
			$/[2] ?? |$/[2].split(/\,\s*/) !! () ] };
	});
}

sub build-tower( @discs ) {
	for @discs -> $d {
		for $d<tower>.kv -> $i, $id {
			my $child  = @discs.first( *<id> eq $id );
			$d<tower>[$i] := $child;
			$child<parent> = $d;
		}
	}

	my @base = @discs.grep({ not $_<parent>:exists });
	die "Unable to build tower!" if @base.elems != 1;
	return @base.first;
}

# You offer to help, but first you need to understand the structure of these
# towers. You ask each program to yell out their name, their weight, and (if
# they're holding a disc) the names of the programs immediately above them
# balancing on that disc. You write this information down (your puzzle input).
# Unfortunately, in their panic, they don't do this in an orderly fashion; by
# the time you're done, you're not sure which program gave which information.
#
# For example, if your list is the following:

my @discs = q{
pbga (66)
xhth (57)
ebii (61)
havc (66)
ktlj (57)
fwft (72) -> ktlj, cntj, xhth
qoyq (66)
padx (45) -> pbga, havc, qoyq
tknk (41) -> ugml, padx, fwft
jptl (61)
ugml (68) -> gyxo, ebii, jptl
gyxo (61)
cntj (57)
}.lines.&parse-discs;


# ...then you would be able to recreate the structure of the towers that looks
# like this:
#                 gyxo
#               /
#          ugml - ebii
#        /      \
#       |         jptl
#       |
#       |         pbga
#      /        /
# tknk --- padx - havc
#      \        \
#       |         goyq
#       |
#       |         ktlj
#        \      /
#          fwft - cntj
#               \
#                 xhth
#
# In this example, tknk is at the bottom of the tower (the bottom program), and is holding up ugml, padx, and fwft. Those programs are, in turn, holding up other programs; in this example, none of those programs are holding up any other programs, and are all the tops of their own towers. (The actual tower balancing in front of you is much larger.)

my $test-tower = build-tower(@discs);
is $test-tower<id>, 'tknk', "Base of the tower is tknk";

# Before you're ready to help them, you need to make sure your information is correct. What is the name of the bottom program?

my $tower = build-tower( parse-discs( "7-input".IO.lines ) );
is $tower<id>, 'qibuqqg', "Correct tower base for input";


# --- Part Two ---
#
# The programs explain the situation: they can't get down. Rather, they could get down, if they weren't expending all of their energy trying to keep the tower balanced. Apparently, one program has the wrong weight, and until it's fixed, they're stuck here.
#
# For any program holding a disc, each program standing on that disc forms a sub-tower. Each of those sub-towers are supposed to be the same weight, or the disc itself isn't balanced. The weight of a tower is the sum of the weights of the programs in that tower.

sub sum-legs($base) 
{
	return $base<tower>.map({
		$_<id> => $_<weight> + sum-legs($_).map(*.value).sum;
    });
}

sub balance-tower($base) {
    my %sums = sum-legs($base).Hash;
    my %weights;
    %weights{.value}++ for %sums<>;

    my ($bad, $good) = %weights.sort(*.value <=> *.value);
    return unless $good;

    my $id   = %sums.first(*.value == $bad.key).key;
    my $disc = $base<tower>.first(*<id> eq $id);

    my $unbalanced = balance-tower( $disc );
    return $unbalanced if $unbalanced;

    my $change = $good.key - $bad.key;
    return $id => $disc<weight> + $change;
}

# In the example above, this means that for ugml's disc to be balanced, gyxo,
# ebii, and jptl must all have the same weight, and they do: 61.
#
# However, for tknk to be balanced, each of the programs standing on its disc
# and all programs above it must each match. This means that the following sums
# must all be the same:
#
#     ugml + (gyxo + ebii + jptl) = 68 + (61 + 61 + 61) = 251
#     padx + (pbga + havc + qoyq) = 45 + (66 + 66 + 66) = 243
#     fwft + (ktlj + cntj + xhth) = 72 + (57 + 57 + 57) = 243
#
# As you can see, tknk's disc is unbalanced: ugml's stack is heavier than the
# other two. Even though the nodes above ugml are balanced, ugml itself is too
# heavy: it needs to be 8 units lighter for its stack to weigh 243 and keep the
# towers balanced. If this change were made, its weight would be 60.
#
# Given that exactly one program is the wrong weight, what would its weight
# need to be to balance the entire tower?

is sum-legs($test-tower), ( ugml => 251, padx => 243, fwft => 243 ),
    "Test sums are correct";

is balance-tower( $test-tower ), ( ugml => 60 ),
    "Have to change ugml's weight to 59 to balance the tower";

is balance-tower( $tower ), ( egbzge => 1079 ),
    "Have to change egbzge's weight to 1079 to balance the tower";

done-testing;
