#!perl6
use Test;

# --- Day 20: Particle Swarm ---
#
# Suddenly, the GPU contacts you, asking for help. Someone has asked it to
# simulate too many particles, and it won't be able to finish them all in time
# to render the next frame at this rate.
#
# It transmits to you a buffer (your puzzle input) listing each particle in
# order (starting with particle 0, then particle 1, particle 2, and so on). For
# each particle, it provides the X, Y, and Z coordinates for the particle's
# position (p), velocity (v), and acceleration (a), each in the format <X,Y,Z>.
#
# Each tick, all particles are updated simultaneously. A particle's properties
# are updated in the following order:

#     Increase the X velocity by the X acceleration.
#     Increase the Y velocity by the Y acceleration.
#     Increase the Z velocity by the Z acceleration.
#     Increase the X position by the X velocity.
#     Increase the Y position by the Y velocity.
#     Increase the Z position by the Z velocity.

# Because of seemingly tenuous rationale involving z-buffering, the GPU would
# like to know which particle will stay closest to position <0,0,0> in the long
# term. Measure this using the Manhattan distance, which in this situation is
# simply the sum of the absolute values of a particle's X, Y, and Z position.
#
# For example, suppose you are only given two particles, both of which stay
# entirely on the X-axis (for simplicity). Drawing the current states of
# particles 0 and 1 (in that order) with an adjacent a number line and diagram
# of current X positions (marked in parenthesis), the following would take
# place:

grammar ParticleList {
    token TOP { <particle>* { make $<particle>.map(*.made).list } }

    rule particle {
        <pair> ',' <pair> ',' <pair>
        { make $<pair>.map(*.made).hash }
    }
    rule pair {
        <key> '=' '<' <value> ',' <value> ',' <value> '>'
        { make $<key>.made => $<value>.map(*.made).list }
    }
    token key   {  <[pva]> { make $/.Str } }
    token value { '-'? \d+ { make $/.Int } }
}

sub read-particles(Str $input) {
    ParticleList.parse($input).made.kv.map({ $^b<i> = $^a; $^b });
}

sub distance-between( $p, $q ) {
    return Nil if $p<destroyed> or $q<destroyed>
               or $p<runaway>   or $q<runaway>;
    my $n =( $p<p>.list Z- $q<p>.list ).map(*.abs).sum;
}

sub calculate-distances(@particles) {
    @particles.map(-> $p {
        my @ret;
        unless $p<runaway> or $p<destroyed> {
            @ret = @particles
                .grep({ $_<i> < $p<i> })
                #.hyper
                .map({ distance-between( $p, $_ ) }).Array;
        }
        @ret;
    }).Array;
}

sub say-distance($_) {
    .map( *.map({ .defined ?? .fmt("%2s") !! ' -' }).join(" ") )
        .join("\n").say;
    "-----".say;
}

sub move-particle($p) {
    $p<v> = ( $p<v>.list Z+ $p<a>.list ).list;
    $p<p> = ( $p<p>.list Z+ $p<v>.list ).list;
    True;
}

sub move-particles( @particles ) {
    @particles.race.map(&move-particle);
    cleanup( @particles, calculate-distances(@particles) );
}

sub cleanup( @particles, @distances ) {
    my @map;
    my %destroyed;
    for @particles -> $p {
        for @particles -> $q {
            last if $p<i> < $q<i>;
            my $v = @distances[$p<i>][$q<i>];

            if $v.defined and $v == 0 {
                ( 'destroyed', $q<i>, $p<i> ).say;
                $v = 'X';
                %destroyed{ $p<i> } = $p;
                %destroyed{ $q<i> } = $q;
            }

            @map[$p<i>][$q<i>] = $v;
        }
    }
    $_<destroyed> = True for %destroyed.values;
    @map;
}

sub distance-change( @prev, @next ) {
    my @distances;
    for @next.cache.keys -> $i {
        for @next[$i].cache.kv -> $j, $n {
            next unless $n.defined and $n.isa(Int);
            my $p = @prev[$i][$j];
            next unless $p.defined and $p.isa(Int);

            @distances[$i][$j] = $n - $p;
        }
    }

    return @distances;
}

sub find-runaways( @particles, @prev, @next ) {
    for @particles -> $p {
        next if $p<runaway> or $p<destroyed>;
        my $closer = False;
        for @particles -> $q {
            last if $p<i> < $q<i>;
            next if $q<runaway> or $q<destroyed>;

            my $a = @prev[ $p<i> ][ $q<i> ];
            my $b = @next[ $p<i> ][ $q<i> ];

            if ($a.isa(Int) and $b.isa(Int) and $a <= $b) {
                $closer = True;
                last;
            }
        }
        #$p<runaway> = True unless $closer;
        ( 'runaway', $p ) unless $closer;
    }
}

{
    my @test-particles = read-particles(q:to/EOL/);
        p=< 3,0,0>, v=< 2,0,0>, a=<-1,0,0>
        p=< 4,0,0>, v=< 0,0,0>, a=<-2,0,0>
        EOL

# p=< 3,0,0>, v=< 2,0,0>, a=<-1,0,0>    -4 -3 -2 -1  0  1  2  3  4
# p=< 4,0,0>, v=< 0,0,0>, a=<-2,0,0>                         (0)(1)
#
# p=< 4,0,0>, v=< 1,0,0>, a=<-1,0,0>    -4 -3 -2 -1  0  1  2  3  4
# p=< 2,0,0>, v=<-2,0,0>, a=<-2,0,0>                      (1)   (0)
#
# p=< 4,0,0>, v=< 0,0,0>, a=<-1,0,0>    -4 -3 -2 -1  0  1  2  3  4
# p=<-2,0,0>, v=<-4,0,0>, a=<-2,0,0>          (1)               (0)
#
# p=< 3,0,0>, v=<-1,0,0>, a=<-1,0,0>    -4 -3 -2 -1  0  1  2  3  4
# p=<-8,0,0>, v=<-6,0,0>, a=<-2,0,0>                         (0)

# At this point, particle 1 will never be closer to <0,0,0> than particle 0,
# and so, in the long run, particle 0 will stay closest.

    is @test-particles.sort(*<a>.sum).tail<i>, 0,
        "Particle 0 has the lowest acceleration so will stay closest";
}
# Which particle will stay closest to position <0,0,0> in the long term?

my @main-particles = read-particles( "20-input".IO.slurp );
my $min-a = @main-particles.map( *<a>.map(*.abs).sum ).min;

my $slowest-particle = @main-particles
    .grep( *<a>.map(*.abs).sum == $min-a )
    .sort( *<v>.map(*.abs).sum )
    .head;
is $slowest-particle<i>, 170,
      "Particle 170 has the lowest acceleration and initial velocity";

# --- Part Two ---
#
# To simplify the problem further, the GPU would like to remove any particles
# that collide. Particles collide if their positions ever exactly match.
# Because particles are updated simultaneously, more than two particles can
# collide at the same time and place. Once particles collide, they are removed
# and cannot collide with anything else after that tick.
#
# For example:
{
    my @test-particles = read-particles( q:to/EOL/);
        p=<-6,0,0>, v=< 3,0,0>, a=< 0,0,0>
        p=<-4,0,0>, v=< 2,0,0>, a=< 0,0,0>
        p=<-2,0,0>, v=< 1,0,0>, a=< 0,0,0>
        p=< 3,0,0>, v=<-1,0,0>, a=< 0,0,0>
        EOL

    #@test-particles.say;

    my @last = calculate-distances( @test-particles );
    my $moves = 1;
    while $moves > 0 {
        #say-distance( @last );
        my @next = move-particles( @test-particles );
        my @moved = distance-change( @last, @next );
#        find-runaways( @test-particles, @last-moved, @moved )
#            if @last-moved.elems;
        $moves = @moved.map(*.flat).flat.grep(*.isa(Int)).grep(* < 0).elems;
        @last = @next;
    }
    #say-distance(@last);

# p=<-6,0,0>, v=< 3,0,0>, a=< 0,0,0>
# p=<-4,0,0>, v=< 2,0,0>, a=< 0,0,0>    -6 -5 -4 -3 -2 -1  0  1  2  3
# p=<-2,0,0>, v=< 1,0,0>, a=< 0,0,0>    (0)   (1)   (2)            (3)
# p=< 3,0,0>, v=<-1,0,0>, a=< 0,0,0>
#
# p=<-3,0,0>, v=< 3,0,0>, a=< 0,0,0>
# p=<-2,0,0>, v=< 2,0,0>, a=< 0,0,0>    -6 -5 -4 -3 -2 -1  0  1  2  3
# p=<-1,0,0>, v=< 1,0,0>, a=< 0,0,0>             (0)(1)(2)      (3)
# p=< 2,0,0>, v=<-1,0,0>, a=< 0,0,0>
#
# p=< 0,0,0>, v=< 3,0,0>, a=< 0,0,0>
# p=< 0,0,0>, v=< 2,0,0>, a=< 0,0,0>    -6 -5 -4 -3 -2 -1  0  1  2  3
# p=< 0,0,0>, v=< 1,0,0>, a=< 0,0,0>                       X (3)
# p=< 1,0,0>, v=<-1,0,0>, a=< 0,0,0>
#
# ------destroyed by collision------
# ------destroyed by collision------    -6 -5 -4 -3 -2 -1  0  1  2  3
# ------destroyed by collision------                      (3)
# p=< 0,0,0>, v=<-1,0,0>, a=< 0,0,0>

    ok @test-particles[0]<destroyed>, "Test Particle 0 is destroyed";
    ok @test-particles[1]<destroyed>, "Test Particle 1 is destroyed";
    ok @test-particles[2]<destroyed>, "Test Particle 2 is destroyed";
    ok !@test-particles[3]<destroyed>, "Test Particle 3 is NOT destroyed";
}

# In this example, particles 0, 1, and 2 are simultaneously destroyed at the
# time and place marked X. On the next tick, particle 3 passes through
# unharmed.
#
# How many particles are left after all collisions are resolved?

{
    my @last = calculate-distances( @main-particles );
    my $moves = 1;
    while $moves > 0 {
        #say-distance( @last );
        my @next = move-particles( @main-particles );
        my @moved = distance-change( @last, @next );
        $moves = @moved.map(*.flat).flat.grep(*.isa(Int)).grep(* < 0).elems;
        @last = @next;
        @main-particles.grep(not *<destroyed>).elems.say;
    }

    @main-particles.grep(not *<destroyed>).elems.say;
}

done-testing;
