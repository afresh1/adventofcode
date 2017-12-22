#!perl6
use Test;

# --- Day 22: Sporifica Virus ---
#
# Diagnostics indicate that the local grid computing cluster has been
# contaminated with the Sporifica Virus. The grid computing cluster is a
# seemingly-infinite two-dimensional grid of compute nodes. Each node is either
# clean or infected by the virus.
#
# To prevent overloading the nodes (which would render them useless to the
# virus) or detection by system administrators, exactly one virus carrier moves
# through the network, infecting or cleaning nodes as it moves. The virus
# carrier is always located on a single node in the network (the current node)
# and keeps track of the direction it is facing.
#
# To avoid detection, the virus carrier works in bursts; in each burst, it
# wakes up, does some work, and goes back to sleep. The following steps are all
# executed in order one time each burst:
#
#     If the current node is infected, it turns to its right. Otherwise, it
#     turns to its left. (Turning is done in-place; the current node does not
#     change.)
#
#     If the current node is clean, it becomes infected. Otherwise, it becomes
#     cleaned. (This is done after the node is considered for the purposes of
#     changing direction.)
#
#     The virus carrier moves forward one node in the direction it is facing.
#
# Diagnostics have also provided a map of the node infection status (your
# puzzle input). Clean nodes are shown as .; infected nodes are shown as #.
# This map only shows the center of the grid; there are many more nodes beyond
# those shown, but none of them are currently infected.
#
# The virus carrier begins in the middle of the map facing up.

class InfectedGrid {
    subset Point of List where { .elems == 2 && .all ~~ Int };

    my Point @directions = (
        (  0,  1 ), # up
        ( -1,  0 ), # left
        (  0, -1 ), # down
        (  1,  0 ), # right
    );

    has Point %!minmax;

    has Int $.total-infections is default(0);
    has %!infected             is default(False);

    # Start at 0, 0 moving up
    #has Int   $!direction is default(0);
    has       $!direction is default(0);
    #has Point $!position  is default( 0, 0 );
    has       $!position  is default( 0, 0 );

    has $!moves   is default(0);

    submethod BUILD(:$grid) {
        my @grid = $grid.lines.map(*.comb);
        my $start = Int( @grid.end / 2 );

        my $y = $start;
        for @grid -> @row {
            my $x = -$start;
            for @row -> $cell {
                self.infect-at("$x:$y", $cell) if $cell ne '.';
                $x++;
            }
            $y--;
        }


        my $y_start = $start;
        if $start < 4 {
            $start   = 4; # make the test grid bigger
            $y_start = 3; # for some reason the test grids are small
        }
        %!minmax = :x( [ -$start, $start ] ), :y( [ -$y_start, $start ] );
        $!total-infections = 0; # reset;
    }

    method move( Int $n = $!moves + 1 ) {
        ( 'move', $n, 'from', $!moves ).say;
        while $!moves < $n {
            $!direction = ( $!direction + self.next-turn ) % @directions.elems;
            self.infect($!position.join(':'));
            $!position
                = ( $!position.list Z+ @directions[$!direction].list ).list;
            $!moves++;
            "... $!moves".say if $!moves % 100_000 == 0;
        }
    }

    method next-turn() { self.current-infection ?? -1 !! 1 }

    method current-infection() { self.infection-at($!position.join(':')) }
    method infection-at($pos) { %!infected{$pos} }
    method infect-at($pos, $infection) {
        $!total-infections++ if $infection eq '#';
        %!infected{$pos} = $infection;
    }
    method infect($pos) {
        my $was-infected = self.infection-at($pos);
        self.infect-at( $pos, $was-infected ?? False !! '#' );
        return $was-infected;
    }

    #method update-minmax() {
    #    %!minmax<x>[0] = $!position[0] if $!position[0] < %!minmax<x>[0];
    #    %!minmax<x>[1] = $!position[0] if $!position[0] > %!minmax<x>[1];
    #    %!minmax<y>[0] = $!position[1] if $!position[1] < %!minmax<y>[0];
    #    %!minmax<y>[1] = $!position[1] if $!position[1] > %!minmax<y>[1];
    #}

    method Str {
        self.gist.map({
            .rotor( 2 => -1, :partial )
            .map({ .all.chars <= 1 ?? "$_[0] " !! $_[0] })
            .join
            .trim
        }).join("\n");
    }

    method gist {
        my @grid;
        for %!minmax<y>[1] ... %!minmax<y>[0] -> $y {
            my @row;
            for %!minmax<x>[0] ... %!minmax<x>[1] -> $x {
                my $cell = self.infection-at("$x:$y") || '.';
                $cell = "[$cell]" if  $!position ~~ ( $x, $y );
                @row.append($cell);
            }
            @grid.push( @row );
        }
        return @grid;
    }
}

{
# For example, suppose you are given a map like this:
    my $test-grid = InfectedGrid.new(:grid(q:to/EOL/) );
        ..#
        #..
        ...
        EOL


# Then, the middle of the infinite grid looks like this, with the virus
# carrier's position marked with [ ]:

    is $test-grid ~ "\n", q:to/EOL/, "Initial grid looks right";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . # . . .
        . . . #[.]. . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# The virus carrier is on a clean node, so it turns left, infects the node, and
# moves left:


    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "First move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . # . . .
        . . .[#]# . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# The virus carrier is on an infected node, so it turns right, cleans the node,
# and moves up:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "Second move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . .[.]. # . . .
        . . . . # . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# Four times in a row, the virus carrier finds a clean, infects it, turns left,
# and moves forward, ending in the same place and still facing up:

    $test-grid.move(6);
    is $test-grid ~ "\n", q:to/EOL/, "Sixth move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . #[#]. # . . .
        . . # # # . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# Now on the same node as before, it sees an infection, which causes it to turn
# right, clean the node, and move forward:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "Seventh move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . # .[.]# . . .
        . . # # # . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# After the above actions, a total of 7 bursts of activity had taken place. Of
# them, 5 bursts of activity caused an infection.

    is $test-grid.total-infections, 5, "Five nodes were infected";

# After a total of 70, the grid looks like this, with the virus carrier facing
# up:

    $test-grid.move(70);
    is $test-grid ~ "\n", q:to/EOL/, "70th move correct";
        . . . . . # # . .
        . . . . # . . # .
        . . . # . . . . #
        . . # . #[.]. . #
        . . # . # . . # .
        . . . . . # # . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# By this time, 41 bursts of activity caused an infection (though most of those
# nodes have since been cleaned).

    is $test-grid.total-infections, 41,
        "41 nodes were infected after 70 moves";

# After a total of 10000 bursts of activity, 5587 bursts will have caused an
# infection.
    $test-grid.move( 10_000 );
    is $test-grid.total-infections, 5587,
        "5587 nodes infected after 10000 bursts";
    #$test-grid.Str.say;
}

# Given your actual map, after 10000 bursts of activity, how many bursts cause
# a node to become infected? (Do not count nodes that begin infected.)
{
    my $main-grid = InfectedGrid.new(:grid("22-input".IO.slurp));
    #$main-grid.Str.say;
    $main-grid.move( 10_000 );
    is $main-grid.total-infections, 5246,
        "5246 nodes infected after 10000 bursts on input grid";
}

# --- Part Two ---
#
# As you go to remove the virus from the infected nodes, it evolves to resist
# your attempt.

class EvolvedInfectedGrid is InfectedGrid {

# Now, before it infects a clean node, it will weaken it to disable your
# defenses. If it encounters an infected node, it will instead flag the node to
# be cleaned in the future. So:

    my @states = ( False, 'W', '#', 'F' );

#     Clean nodes become weakened.
#
#     Weakened nodes become infected.
#
#     Infected nodes become flagged.
#
#     Flagged nodes become clean.
#
# Every node is always in exactly one of the above states.

    method infect($pos) {
        my $prev = self.infection-at($pos);
        my $next-i = ( $prev ?? @states.first({ $_ ~~ $prev }, :k) + 1 !! 1 );
        $next-i   %= @states;
        my $next = @states[$next-i];
        self.infect-at($pos, $next );
        return $prev;
    }

# The virus carrier still functions in a similar way, but now uses the
# following logic during its bursts of action:
#
#     Decide which way to turn based on the current node:
#
#         If it is clean, it turns left.
#
#         If it is weakened, it does not turn, and will continue moving in the
#         same direction.
#
#         If it is infected, it turns right.
#
#         If it is flagged, it reverses direction, and will go back the way it
#         came.  Modify the state of the current node, as described above.

    method next-turn() {
        given self.current-infection {
            when {!$_} { 1 }
            when 'W' { 0 }
            when '#' { 3 }
            when 'F' { 2 }
            default { die "Unknown direction $_" }
        }
    }

#     The virus carrier moves forward one node in the direction it is facing.

}

# Start with the same map (still using . for clean and # for infected) and
# still with the virus carrier starting in the middle and facing up.
{
# Using the same initial state as the previous example, and drawing weakened as
# W and flagged as F, the middle of the infinite grid looks like this, with the
# virus carrier's position again marked with [ ]:

    my $test-grid = EvolvedInfectedGrid.new(:grid(q:to/EOL/) );
        ..#
        #..
        ...
        EOL

    is $test-grid ~ "\n", q:to/EOL/, "Initial map OK";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . # . . .
        . . . #[.]. . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# This is the same as before, since no initial nodes are weakened or flagged.
# The virus carrier is on a clean node, so it still turns left, instead weakens
# the node, and moves left:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "First move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . # . . .
        . . .[#]W . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# The virus carrier is on an infected node, so it still turns right, instead
# flags the node, and moves up:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "Second move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . .[.]. # . . .
        . . . F W . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# This process repeats three more times, ending on the previously-flagged node
# and facing right:

    $test-grid.move(5);
    is $test-grid ~ "\n", q:to/EOL/, "Fifth move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . W W . # . . .
        . . W[F]W . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# Finding a flagged node, it reverses direction and cleans the node:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "First move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . W W . # . . .
        . .[W]. W . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# The weakened node becomes infected, and it continues in the same direction:

    $test-grid.move;
    is $test-grid ~ "\n", q:to/EOL/, "First move correct";
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . W W . # . . .
        .[.]# . W . . . .
        . . . . . . . . .
        . . . . . . . . .
        . . . . . . . . .
        EOL

# Of the first 100 bursts, 26 will result in infection.

    $test-grid.move(100);
    is $test-grid.total-infections, 26, "After 100 bursts, 26 infections";

# Unfortunately, another feature of this evolved virus is speed; of the first
# 10000000 bursts, 2511944 will result in infection.

    $test-grid.move(10_000_000);
    is $test-grid.total-infections, 2_511_944,
        "After 10 million bursts, 2,511,944 infections";
}

# Given your actual map, after 10000000 bursts of activity, how many bursts
# cause a node to become infected? (Do not count nodes that begin infected.)
{
    my $main-grid = EvolvedInfectedGrid.new(:grid("22-input".IO.slurp));
    #$main-grid.Str.say;
    $main-grid.move( 10_000_000 );
    is $main-grid.total-infections, 2_512_059,
        "2,512,059 nodes infected after 10,000,000 bursts on input grid";
}

done-testing;
