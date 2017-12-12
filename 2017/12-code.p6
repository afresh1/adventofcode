#!perl6
use Test;

# --- Day 12: Digital Plumber ---
#
# Walking along the memory banks of the stream, you find a small village that
# is experiencing a little confusion: some programs can't communicate with each
# other.
#
# Programs in this village communicate using a fixed system of pipes. Messages
# are passed between programs using these pipes, but most programs aren't
# connected to each other directly. Instead, programs pass messages between
# each other until the message reaches the intended recipient.
#
# For some reason, though, some of these messages aren't ever reaching their
# intended recipient, and the programs suspect that some pipes are missing.
# They would like you to investigate.
#
# You walk through the village and record the ID of each program and the IDs
# with which it can communicate directly (your puzzle input). Each program has
# one or more programs with which it can communicate, and these pipes are
# bidirectional; if 8 says it can communicate with 11, then 11 will say it can
# communicate with 8.
#
# You need to figure out how many programs are in the group that contains
# program ID 0.

sub parse-pipes($_) {
    .lines
        .map({ .split(/\s* '<->' \s*/, :limit(2)) })
        .kv.map( *.first => *.tail.split(/\s* ',' \s*/).map(*.Int) );
}

sub pipe-to-zero(%pipes) {
    my %pipes-to-zero = 0 => True;
    my @p = %pipes.keys;

    while ( my $source = shift @p ) {
        next unless %pipes-to-zero{$source};
        for (%pipes{$source}.cache.flat) -> $dest {
            next unless $dest;
            next if %pipes-to-zero{$dest};
            %pipes-to-zero{$dest} = True;
            @p.push: $dest;
        }
    }
    return %pipes-to-zero.keys.sort;
}

sub group-programs(%pipes) {
    my %nodes = %pipes.keys.map( * => {} );

    for %pipes.keys -> $source {
        for %pipes{$source}.cache.flat -> $dest {
            next unless $dest;
            %nodes{$dest}{$source} := %nodes{$source};
            %nodes{$source}{$dest} := %nodes{$dest};
        }
    }

    my %networks;
    for %nodes.keys.sort -> $source {
        my %seen;
        %networks{$source} = $source;
        my @dests = %nodes{$source}.values.flat;
        while @dests {
            my %pipes = @dests.shift;
            for %pipes.keys.sort -> $dest {
                next if %seen{$dest}++;
                %networks{$source} = $dest if $dest < %networks{$source};
                @dests.push: %pipes{$dest}.flat;
            }
        }
    }
    my %groups;
    for %networks.sort.invert {
        %groups{ .key }.push: .value;
    }
    return %groups;
}

# For example, suppose you go door-to-door like a travelling salesman and
# record the following list:

{
# In this example, the following programs are in the group that contains
# program ID 0:

    my $input = q:to/EOL/;
    0 <-> 2
    1 <-> 1
    2 <-> 0, 3, 4
    3 <-> 2, 4
    4 <-> 2, 3, 6
    5 <-> 6
    6 <-> 4, 5
    EOL

#     Program 0 by definition.
#     Program 2, directly connected to program 0.
#     Program 3 via program 2.
#     Program 4 via program 2.
#     Program 5 via programs 6, then 4, then 2.
#     Program 6 via programs 4, then 2.
#
# Therefore, a total of 6 programs are in this group; all but program 1, which
# has a pipe that connects it to itself.

    my %pipes = parse-pipes($input);
    my @zero-group = group-programs(%pipes){0};

    is @zero-group, < 0 2 3 4 5 6 >,
        "zero group is all programs except '1'";

    is @zero-group, pipe-to-zero( %pipes ),
        "zero group double checks accurately";
}

# How many programs are in the group that contains program ID 0?

my %program-groups = group-programs( parse-pipes( "12-input".IO ).hash );
is %program-groups{0}.elems, 152, "152 programs in group zero";

# --- Part Two ---
#
# There are more programs than just the ones in the group containing program ID
# 0. The rest of them have no way of reaching that group, and still might have
# no way of reaching each other.
#
# A group is a collection of programs that can all communicate via pipes either
# directly or indirectly. The programs you identified just a moment ago are all
# part of the same group. Now, they would like you to determine the total
# number of groups.
#
# In the example above, there were 2 groups: one consisting of programs
# 0,2,3,4,5,6, and the other consisting solely of program 1.
#
# How many groups are there in total?

is %program-groups.keys.elems, 186, "186 groups total";

done-testing;
