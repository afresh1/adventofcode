#!perl6
use Test;

# --- Day 13: Packet Scanners ---
#
# You need to cross a vast firewall. The firewall consists of several layers,
# each with a security scanner that moves back and forth across the layer. To
# succeed, you must not be detected by a scanner.
#
# By studying the firewall briefly, you are able to record (in your puzzle
# input) the depth of each layer and the range of the scanning area for the
# scanner within it, written as depth: range. Each layer has a thickness of
# exactly 1. A layer at depth 0 begins immediately inside the firewall; a layer
# at depth 1 would start immediately after that.

class SecurityScanner {
    has Int $!period    is default(0);
    has Int $!position  is default(0);# where { $_ < $!period };

    multi method new(Pair $_) {
        self.bless( :period(.key), :position(.value) )
    }
    multi method new(Int $period, Int $position=0) {
        self.bless( :period($period), :position($position) );
    }

    submethod BUILD(:$!period, :$!position=0) {}

    method detecting(Int $i = 0) { return $i == $!position ?? $!period !! 0 }

    method tick() {
        $!position *= -1 if $!position == $!period - 1;
        $!position++
    }

    method Str  {
        my $p = $!position.abs;
        (0..($!period-1)).map({ $_ == $p ?? "[S]" !! "[ ]" }).join;
    }

    method gist { $!period => $!position }
}

class Firewall {
    has @.layers;
    has Int $!packet;
    has Int @.scores;

    multi method new(%config) { self.bless(|%config) }
    multi method new(@scanners) {
        my @layers;
        @layers[ .first ] = .tail for @scanners;
        return self.bless(:layers(@layers));
    }
    submethod BUILD(:@layers, :$packet, :@!scores) {
        $!packet := $packet if $packet.isa(Int) && $packet.defined;
        @!layers = @layers.map({
            .defined ?? SecurityScanner.new($_) !! $_
        } );
    }

    method inject() { $!packet = 0 }
    method processing-packet() { $!packet.defined }
    method detected-packet()   { self.scores.sum != 0 }

    method detect() {
        return unless self.processing-packet;
        for @!layers.kv -> $i, $s {
            @!scores[$i] //= 0;
            if $s.defined && $!packet == $i {
                @!scores[$i] = $s.detecting;
            }
        }
    }

    method severity() { @!scores.kv.map( * * * ).sum }

    method tick() { self.tick-scanners; self.tick-packet  }
    method tick-scanners() {
        self.detect;
        .tick for @!layers.grep(*.can('tick')
    ) }
    method tick-packet() {
        return unless self.processing-packet;

        $!packet++;
        $!packet = Nil if $!packet == @!layers.elems;
    }

    method clone {
        nextwith :scores( @.scores.clone ), :layers( @!layers.map(*.clone) );
    }

    method Str {
        my $rows = @!layers.grep(*.defined).map(*.gist.key).max - 1;
        (0..$rows).map( -> $r {
            @!layers.keys.map( -> $i {
                if @!layers[$i] {
                    my $s = @!layers[$i].gist;
                    if $r >= $s.key { '   ' }
                    else {
                        my $v = $s.value.abs == $r ?? 'S' !! ' ';
                        $!packet ~~ $i && $r == 0 ?? "($v)" !! "[$v]";
                    }
                }
                elsif $r == 0 { $!packet ~~ $i && $r == 0 ?? '(.)' !! '...' }
                else          { '   ' }
            }).join(' ');
        }).join("\n");
    }
    method gist() { {
        packet => $!packet,
        layers => @!layers.map({ .isa(SecurityScanner) ?? .gist !! $_ }),
        scores => @!scores,
    } }
}

sub read-config($config) { $config.lines.map(*.comb(/\d+/).map(*.Int).List) }

my @config = read-config( q:to/EOL/ );
    0: 3
    1: 2
    4: 4
    6: 4
    EOL

# For example, suppose you've recorded the following:
subtest {
    my $fw = Firewall.new(@config);

# This means that there is a layer immediately inside the firewall (with range 3), a second layer immediately after that (with range 2), a third layer which begins at depth 4 (with range 4), and a fourth layer which begins at depth 6 (also with range 4). Visually, it might look like this:

#  0   1   2   3   4   5   6
# [ ] [ ] ... ... [ ] ... [ ]
# [ ] [ ]         [ ]     [ ]
# [ ]             [ ]     [ ]
#                 [ ]     [ ]

# Within each layer, a security scanner moves back and forth within its range.
# Each security scanner starts at the top and moves down until it reaches the
# bottom, then moves up until it reaches the top, and repeats. A security
# scanner takes one picosecond to move one step. Drawing scanners as S, the
# first few picoseconds look like this:
#
#
# Picosecond 0:
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 0";
    [S] [S] ... ... [S] ... [S]
    [ ] [ ]         [ ]     [ ]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL

    $fw.tick;
# Picosecond 1:
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 1";
    [ ] [ ] ... ... [ ] ... [ ]
    [S] [S]         [S]     [S]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL

    $fw.tick;
# Picosecond 2:
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 2";
    [ ] [S] ... ... [ ] ... [ ]
    [ ] [ ]         [ ]     [ ]
    [S]             [S]     [S]
                    [ ]     [ ]
    EOL

    $fw.tick;
# Picosecond 3:
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 3";
    [ ] [ ] ... ... [ ] ... [ ]
    [S] [S]         [ ]     [ ]
    [ ]             [ ]     [ ]
                    [S]     [S]
    EOL
}, "Scanning";

subtest {
# Your plan is to hitch a ride on a packet about to move through the firewall.
# The packet will travel along the top of each layer, and it moves at one layer
# per picosecond. Each picosecond, the packet moves one layer forward (its
# first move takes it into layer 0), and then the scanners move one step. If
# there is a scanner at the top of the layer as your packet enters it, you are
# caught. (If a scanner moves into the top of its layer while you are there,
# you are not caught: it doesn't have time to notice you before you leave.) If
# you were to do this in the configuration above, marking your current position
# with parentheses, your passage through the firewall would look like this:
#
    my $fw = Firewall.new(@config);
# Initial state:
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Initial State";
    [S] [S] ... ... [S] ... [S]
    [ ] [ ]         [ ]     [ ]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL

ok !$fw.processing-packet, "Not processing a packet before injection";

    {
        my $restored = Firewall.new( $fw.gist );
        is $restored, $fw, "Restored firewall looks like the old one";
        is $restored.scores, $fw.scores, "Restored current score";
    }

# Picosecond 0:
$fw.inject;
ok $fw.processing-packet, "After injection, now processing packet";
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 0 (Packet Inject)";
    (S) [S] ... ... [S] ... [S]
    [ ] [ ]         [ ]     [ ]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 0 (Scanners)";
    ( ) [ ] ... ... [ ] ... [ ]
    [S] [S]         [S]     [S]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL


# Picosecond 1:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 1 (Packet)";
[ ] ( ) ... ... [ ] ... [ ]
[S] [S]         [S]     [S]
[ ]             [ ]     [ ]
                [ ]     [ ]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 1 (Scanners)";
    [ ] (S) ... ... [ ] ... [ ]
    [ ] [ ]         [ ]     [ ]
    [S]             [S]     [S]
                    [ ]     [ ]
    EOL

# Picosecond 2:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 2 (Packet)";
[ ] [S] (.) ... [ ] ... [ ]
[ ] [ ]         [ ]     [ ]
[S]             [S]     [S]
                [ ]     [ ]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 2 (Scanners)";
    [ ] [ ] (.) ... [ ] ... [ ]
    [S] [S]         [ ]     [ ]
    [ ]             [ ]     [ ]
                    [S]     [S]
    EOL

    {
        my $restored = Firewall.new( $fw.gist );
        is $restored, $fw, "Restored firewall looks like the old one";
        is $restored.scores, $fw.scores, "Restored current score";
    }

# Picosecond 3:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 3 (Packet)";
[ ] [ ] ... (.) [ ] ... [ ]
[S] [S]         [ ]     [ ]
[ ]             [ ]     [ ]
                [S]     [S]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 3 (Scanners)";
    [S] [S] ... (.) [ ] ... [ ]
    [ ] [ ]         [ ]     [ ]
    [ ]             [S]     [S]
                    [ ]     [ ]
    EOL
#
# Picosecond 4:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 4 (Packet)";
[S] [S] ... ... ( ) ... [ ]
[ ] [ ]         [ ]     [ ]
[ ]             [S]     [S]
                [ ]     [ ]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 4 (Scanners)";
    [ ] [ ] ... ... ( ) ... [ ]
    [S] [S]         [S]     [S]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL
#
# Picosecond 5:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 5 (Packet)";
[ ] [ ] ... ... [ ] (.) [ ]
[S] [S]         [S]     [S]
[ ]             [ ]     [ ]
                [ ]     [ ]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 5 (Scanners)";
    [ ] [S] ... ... [S] (.) [S]
    [ ] [ ]         [ ]     [ ]
    [S]             [ ]     [ ]
                    [ ]     [ ]
    EOL

# Picosecond 6:
$fw.tick-packet;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 5 (Packet)";
[ ] [S] ... ... [S] ... (S)
[ ] [ ]         [ ]     [ ]
[S]             [ ]     [ ]
                [ ]     [ ]
EOL

$fw.tick-scanners;
#  0   1   2   3   4   5   6
is $fw.Str ~ "\n", q:to/EOL/, "Picosecond 6 (Scanners)";
    [ ] [ ] ... ... [ ] ... ( )
    [S] [S]         [S]     [S]
    [ ]             [ ]     [ ]
                    [ ]     [ ]
    EOL

$fw.tick-packet;
ok !$fw.processing-packet, "After reaching the end, No longer processing";

    {
        my $restored = Firewall.new( $fw.gist );
        is $restored, $fw, "Restored firewall looks like the old one";
        is $restored.scores, $fw.scores, "Restored current score";
    }

# In this situation, you are caught in layers 0 and 6, because your packet
# entered the layer when its scanner was at the top when you entered it. You
# are not caught in layer 1, since the scanner moved into the top of the layer
# once you were already there.
#
# The severity of getting caught on a layer is equal to its depth multiplied by
# its range. (Ignore layers in which you do not get caught.) The severity of
# the whole trip is the sum of these values. In the example above, the trip
# severity is 0*3 + 6*4 = 24.

is $fw.scores, [ 3, 0, 0, 0, 0, 0, 4 ], "Detected at position 0 and 6";
is $fw.severity, 24, "-> for a severity of 24";

}, "Injected Packet";

# Given the details of the firewall you've recorded, if you leave immediately,
# what is the severity of your whole trip?

subtest {
    my @config = read-config("13-input".IO);
    my $fw = Firewall.new(@config);
    $fw.inject;
    while $fw.processing-packet {
        #$fw.Str.say;
        $fw.tick;
    }
    is $fw.severity, 1612, "Severity of 1612";
}, "Input Test 1";

# What is the fewest number of picoseconds that you need to delay the packet to
# pass through the firewall without being caught?

subtest {
    my @config = read-config("13-input".IO);
    my $delay = 0;
    my $save = Firewall.new(@config);

    while True {
        $delay++;
        $save.tick-scanners;

        ( $delay, $save.gist.perl ).say if $delay % 1000 == 0;

        my $fw = $save.clone;
        #$fw.Str.say;
        $fw.inject;
        while $fw.processing-packet && !$fw.detected-packet {
            #$fw.Str.say;
            $fw.tick;
        }

        ( $delay.fmt("%7d ") ~ $fw.scores.map({ $_ == 0 ?? '.' !! '#' }) ).say
            if $delay % 99 == 0;

        $fw.Str.say if not $fw.detected-packet;
        last unless $fw.detected-packet;
    }

    is $delay, 3907994, "found appropriate delay to sneak through";
}, "Find delay for zero score";


done-testing;
