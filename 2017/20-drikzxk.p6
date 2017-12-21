#!/usr/bin/env perl6
use v6.c;

# Advent of Code 2017, day 20: http://adventofcode.com/2017/day/20
# https://www.reddit.com/r/adventofcode/comments/7kz6ik/2017_day_20_solutions/drikzxk/

grammar ParticleProperties
{
    rule TOP { ^ <particle>+ $ }

    rule particle { 'p' '=' <p=coord> ',' 'v' '=' <v=coord> ',' 'a' '=' <a=coord> }
    rule coord { '<' <num>+ % ',' '>' }
    token num { '-'? \d+ }
}

class Particle
{
    has Int @.position;
    has Int @.velocity;
    has Int @.acceleration;

    # Triangle numbers
    sub T(Int $n) { ($n * ($n+1)) div 2; }

    sub manhattan-distance(Int @coord) { @coord».abs.sum }

    multi sub solve-quadratic(0, $b, $c)
    {
        # If a = 0, it's a linear equation
        return -$c / $b;
    }
    multi sub solve-quadratic($a, $b, $c)
    {
        my $D = $b² - 4*$a*$c;
        if $D > 0 {
            return (-$b + $D.sqrt) / (2*$a), (-$b - $D.sqrt) / (2*$a);
        }
        elsif $D == 0 {
            return -$b / (2*$a);
        }
        else {
            return Empty;
        }
    }

    method position-after(Int $t)
    {
        @!position »+« $t «*« @!velocity »+« T($t) «*« @!acceleration;
    }

    method distance-after(Int $t)
    {
        manhattan-distance(self.position-after($t));
    }

    method manhattan-acceleration
    {
        manhattan-distance(@!acceleration);
    }

    method will-collide-with(Particle $p) returns Int
    {
        # First, find out at which times (if any) the x coordinates will collide.
        # This handles the case where two particles have the same acceleration in the x
        # direction (in which case the quadratic equation becomes a linear one), but not
        # the case where they have the same acceleration and velocity.  Luckily, this
        # does not occur in my input data.
        my $pos-x = @!position[0] - $p.position[0];
        my $vel-x = @!velocity[0] - $p.velocity[0];
        my $acc-x = @!acceleration[0] - $p.acceleration[0];
        my @t = solve-quadratic($acc-x, $acc-x + 2*$vel-x, 2*$pos-x);

        # Only non-negative integers are valid options
        # (Deal with approximate values because of possible inexact sqrt)
        @t .= grep({ $_ ≥ 0 && $_ ≅ $_.round });
        @t .= map(*.round);

        # For all remaining candidate times, see if all coordinates match
        for @t.sort -> $t {
            return $t but True if self.position-after($t) eqv $p.position-after($t);
        }

        # No match, so no collision
        return -1 but False;
    }
}

class ParticleCollection
{
    has Particle @.particles;

    method particle($/)
    {
        @!particles.push: Particle.new(:position($/<p><num>».Int),
                                       :velocity($/<v><num>».Int),
                                       :acceleration($/<a><num>».Int));
    }

    method closest-in-long-term
    {
        # In the long term, the particle with the smallest acceleration will be the closest.
        # (Note that this doesn't handle particles with the same acceleration, you'd need to
        # look at the velocities in that case.)
        my $min-acceleration = @!particles».manhattan-acceleration.min;
        my @p = @!particles.pairs.grep(*.value.manhattan-acceleration == $min-acceleration);
        if (@p > 1) {
            say "Warning: there are { +@p } particles with the same minimum acceleration!";
        }
        return @p[0].key;
    }

    method count-non-colling-particles
    {
        # First, collect all possible collisions, and remember them by the time they occur
        my @collisions;
        for ^@!particles -> $i {
            for $i^..^@!particles -> $j {
                if my $c = @!particles[$i].will-collide-with(@!particles[$j]) {
                    @collisions[$c].push(($i, $j));
                }
            }
        }

        # Then, loop through all times where collisions occur, and remove all colliding
        # particle pairs, as long as both particles still exist at that time.
        my @surviving = True xx @!particles;
        for @collisions.grep(?*) -> @c {
            my @remaining = @surviving;
            for @c -> ($i, $j) {
                @remaining[$i] = @remaining[$j] = False if @surviving[$i] && @surviving[$j];
            }
            @surviving = @remaining;
        }

        return @surviving.sum;
    }
}

multi sub MAIN(IO() $inputfile where *.f, Bool :v(:$verbose) = False)
{
    my $pc = ParticleCollection.new;
    ParticleProperties.parsefile($inputfile, :actions($pc)) or die "Can't parse particle properties!";
    say "{ +$pc.particles } particles parsed." if $verbose;

    # Part one
    say "The closest particle in the long term is #{ $pc.closest-in-long-term }.";

    # Part two
    say "The number of particles left after all collisions are resolved is ",
                                                "{ $pc.count-non-colling-particles }.";
}

multi sub MAIN(Bool :v(:$verbose) = False)
{
    MAIN($*PROGRAM.parent.child('20-input'), :$verbose);
}

