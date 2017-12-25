#!perl6
use Test;

# --- Day 24: Electromagnetic Moat ---
#
# The CPU itself is a large, black building surrounded by a bottomless pit.
# Enormous metal tubes extend outward from the side of the building at regular
# intervals and descend down into the void. There's no way to cross, but you
# need to get inside.
#
# No way, of course, other than building a bridge out of the magnetic
# components strewn about nearby.
#
# Each component has two ports, one on each end. The ports come in all
# different types, and only matching types can be connected. You take an
# inventory of the components by their port types (your puzzle input). Each
# port is identified by the number of pins it uses; more pins mean a stronger
# connection for your bridge. A 3/7 component, for example, has a type-3 port
# on one side, and a type-7 port on the other.
#
# Your side of the pit is metallic; a perfect surface to connect a magnetic,
# zero-pin port. Because of this, the first port you use must be of type 0. It
# doesn't matter what type of port you end with; your goal is just to make the
# bridge as strong as possible.

sub find-bridges(@components) {
    @components.combinations.grep({
        my %e = .map(*.flat).flat
            .classify({ $_ }).map({ .key => .value.elems });

        # This doesn't take into account that some of those numbers
        # might be in the same component, so I'm not sure what that means.
        # I believe it just means this isn't as limiting as it should be.
        given %e{0} {
            when !.defined { False }

            # If we have an even number of 0's,
            # it means one at either end, so all others must match
            when * % 2 == 0 { %e.values.all % 2 == 0 }

            # If we have an odd number of zeros,
            # there can be one other number with an odd number of elements
            default { %e.grep({ .value % 2 != 0 }) <= 2; }
        }
    })
    .grep({ .permutations.hyper(:batch(8)).first({
        my $last  = 0;
        my $match = True;
        for $_ {
            if    $last == .head { $last  = .tail }
            elsif $last == .tail { $last  = .head }
            else                 { $match = False; last }
        }
        bridge-to-str($_).say if $match;
        $match;
    }) })
}

sub find-strongest-bridge( @components, @current = [], $last = 0 ) {

    my $component-score = bridge-score( @components );
    my $current-score   = bridge-score( @current );
    my $strongest-score = $current-score;
    my @strongest       = @current;

    my @fail;
    while @components {
        my $c = @components.shift;

        my $match = Nil;
        if    $last == $c.head { $match = $c.tail }
        elsif $last == $c.tail { $match = $c.head }

        if $match.defined {
            $component-score -= $c.sum;
            return @strongest
                if $strongest-score > $current-score + $component-score;

            my @bridge = find-strongest-bridge(
                [ |@components, |@fail ],
                [ |@current, $c ],
                $match,
            );
            my $bridge-score = bridge-score( @bridge );
            if $bridge-score > $strongest-score {
                @strongest = @bridge;
                $strongest-score = $bridge-score;
            }

        }
        else  { @fail.append( $c ) }
    }
    #"Strongest: $strongest-score".say;
    #bridge-to-str(@strongest).say;
    return @strongest;
}

sub find-longest-bridges( @components, $current = [], $last = 0 ) {
    my @longest = [ $current ];

    my @tail;
    while @components {
        return @longest
            if @longest.first.elems
                > $current.elems + @components.elems + @tail.elems;

        my $c = @components.shift;

        my $match = Nil;
        if    $last == $c.head { $match = $c.tail }
        elsif $last == $c.tail { $match = $c.head }

        if $match.defined {
            my @bridges = find-longest-bridges(
                [ |@components, |@tail ],
                [ |$current, $c ],
                $match,
            );

            my @all = ( |@longest, |@bridges );
            my $max = @all.map(*.elems).max;
            @longest = @all.grep( *.elems == $max );
        }

        @tail.append( $c );
    }

    # ( 'longest', @longest.first.elems ).say;
    return @longest;
}

sub bridge-to-str($bridge) { $bridge.map( *.join('/') ).join('--') }
sub bridge-score($bridge)  { $bridge.map(*.flat).flat.sum }

# The strength of a bridge is the sum of the port types in each component. For
# example, if your bridge is made of components 0/3, 3/7, and 7/4, your bridge
# has a strength of 0+3 + 3+7 + 7+4 = 24.
#
# For example, suppose you had the following components:
my @test-components = q:to/EOL/.lines.map(*.comb(/\d+/).map(*.Int).list);
    0/2
    2/2
    2/3
    3/4
    3/5
    0/1
    10/1
    9/10
    EOL

my @test-bridges = find-bridges( @test-components );
#@test-bridges.map(*.say);

# With them, you could make the following valid bridges:
my @expect = q:to/EOL/.lines;
    0/1
    0/1--10/1
    0/1--10/1--9/10
    0/2
    0/2--2/3
    0/2--2/3--3/4
    0/2--2/3--3/5
    0/2--2/2
    0/2--2/2--2/3
    0/2--2/2--2/3--3/4
    0/2--2/2--2/3--3/5
    EOL

is-deeply @test-bridges.map({ bridge-to-str($_) }).Set, @expect.Set,
    "Found all the bridges available";

# (Note how, as shown by 10/1, order of ports within a component doesn't
# matter. However, you may only use each port on a component once.)
#
# Of these bridges, the strongest one is 0/1--10/1--9/10; it has a strength of
# 0+1 + 1+10 + 10+9 = 31.
{
    my $strongest = @test-bridges.sort(*.&bridge-score).tail;
    is bridge-to-str( $strongest ), '0/1--10/1--9/10',
        "Found the strongest bridge";
    is bridge-score( $strongest ), 31, "Strongest bridge is 31 strength";
}
{
    my $strongest = find-strongest-bridge(
        @test-components.sort(*.sum).reverse.Array );

    is bridge-to-str( $strongest ), '0/1--10/1--9/10',
        "Found the strongest bridge";
    is bridge-score( $strongest ), 31, "Strongest bridge is 31 strength";
}

# What is the strength of the strongest bridge you can make with the components
# you have available?
if False
{
    my @main-components
        = "24-input".IO.lines.map(*.comb(/\d+/).map(*.Int).list);

    #my @test-bridges = find-bridges( @main-components );
    #is @test-bridges.elems, 0, "Found 0 bridges in main";
    #my $strongest = @test-bridges.sort(*.&bridge-score).tail;

    my $strongest = find-strongest-bridge(
        @main-components.sort(*.sum).reverse.Array  );
    #is bridge-to-str( $strongest ), '', "Found the strongest real bridge";
    is bridge-score( $strongest ), 2006, "strength of strongest bridge is 2006";
}

# --- Part Two ---
#
# The bridge you've built isn't long enough; you can't jump the rest of the
# way.
#
# In the example above, there are two longest bridges:
#
#     0/2--2/2--2/3--3/4 0/2--2/2--2/3--3/5
#
# Of them, the one which uses the 3/5 component is stronger; its strength is
# 0+2 + 2+2 + 2+3 + 3+5 = 19.
{
    {
        my $max-length = @test-bridges.map(*.elems).max;
        my @longest  = @test-bridges.grep({ $_.elems == $max-length });

        is @longest.map(*.&bridge-to-str),
            [ '0/2--2/2--2/3--3/4', '0/2--2/2--2/3--3/5' ],
            "Found the longest bridge";

        my $strongest-longest = @longest.sort(*.&bridge-score).tail;
        is bridge-to-str( $strongest-longest ), '0/2--2/2--2/3--3/5',
            "Strongest longest test bridge as expected";
    }
    {
        my @longest = find-longest-bridges(
            @test-components.sort(*.sum).reverse.Array );

        is @longest.map(*.&bridge-to-str).sort,
            [ '0/2--2/2--2/3--3/4', '0/2--2/2--2/3--3/5' ],
            "Found the longest bridge";

        my $strongest-longest = @longest.sort(*.&bridge-score).tail;
        is bridge-to-str( $strongest-longest ), '0/2--2/2--2/3--3/5',
            "Strongest longest test bridge as expected";
        is bridge-score( $strongest-longest ), 19,
            "strength of strongest bridge is 19";
    }
}

#
# What is the strength of the longest bridge you can make? If you can make
# multiple bridges of the longest length, pick the strongest one.
{
    my @main-components
        = "24-input".IO.lines.map(*.comb(/\d+/).map(*.Int).list);

    my @longest = find-longest-bridges(
        @main-components.sort(*.sum).reverse.Array );
    my $strongest-longest = @longest.sort(*.&bridge-score).tail;
    is bridge-to-str( $strongest-longest ), '0/39--39/30--44/30--44/5--5/5--5/37--20/37--38/20--38/23--23/40--40/24--24/14--14/45--47/45--47/11--45/11--45/50--46/50--46/17--2/17--2/31--36/31--50/36--41/50--41/35--30/35--4/30--49/4--49/41--32/41--3/32--17/3--22/17--22/48',
        "Strongest longest test bridge as expected";
    is bridge-score( $strongest-longest ), 1994,
        "strength of strongest longest bridge is 1994";
}


done-testing;
