#!/usr/local/bin/perl6
use v6;
use Test;

sub parse-state (@lines) {
    my %convert = ( '#' => 1, '.' => 0, '' => 0 );
    my @state = @lines.map({ .split('')
        .map({ %convert{$_} }).Array }).Array;
    my @blank = ( 0 xx @state[0].elems );
    @state = ( @blank, |@state, @blank );
}

sub count-lights (@state) { return [+] @state.flat.map({ [+] .flat }) }

sub next-state (@state) {
    my @next = @state.map({ [ 0 xx @state[0].elems ] });

    state @coords = [ -1, 0, 1 ];

    for [1 .. @state.end - 1] -> $i {
        my @row := @state[$i];

        for [1 .. @row.end - 1] -> $j {
            my $light := @state[$i][$j];
            my $count = @coords.map({ $_ + $i }).map( -> $ni {
                @coords.map({ $_ + $j }).map( -> $nj { @state[$ni][$nj] });
            }).flat.reduce(&[+]) - $light;

            if ($light) { @next[$i][$j] = 1 if $count ∈ set( 2, 3 ) }
            else        { @next[$i][$j] = 1 if $count == 3 }
        }
    }

    return @next;
}

sub next-stuck-state (@state) {
    my &set-corners = sub (@a) {
        my $e = @a[0].end - 1;
        @a[ 1][ 1] = 1;
        @a[ 1][$e] = 1;
        @a[$e][$e] = 1;
        @a[$e][ 1] = 1;
        return @a;
    }

    my @next = next-state( set-corners(@state) );
    return set-corners(@next);
}

my @test-lights = [
    [    #Initial state:
        '.#.#.#',
        '...##.',
        '#....#',
        '..#...',
        '#.#..#',
        '####..',
    ],
    [    #After 1 step:
        '..##..',
        '..##.#',
        '...##.',
        '......',
        '#.....',
        '#.##..',
    ],
    [    #After 2 steps:
        '..###.',
        '......',
        '..###.',
        '......',
        '.#....',
        '.#....',
    ],
    [    #After 3 steps:
        '...#..',
        '......',
        '...#..',
        '..##..',
        '......',
        '......',
    ],
    [    # After 4 steps:
        '......',
        '......',
        '..##..',
        '..##..',
        '......',
        '......',
    ],
];

my @stuck-lights = [
    [    # Initial state:
        '##.#.#',
        '...##.',
        '#....#',
        '..#...',
        '#.#..#',
        '####.#',
    ],
    [    # After 1 step:
        '#.##.#',
        '####.#',
        '...##.',
        '......',
        '#...#.',
        '#.####',
    ],
    [    # After 2 steps:
        '#..#.#',
        '#....#',
        '.#.##.',
        '...##.',
        '.#..##',
        '##.###',
    ],
    [    # After 3 steps:
        '#...##',
        '####.#',
        '..##.#',
        '......',
        '##....',
        '####.#',
    ],
    [    # After 4 steps:
        '#.####',
        '#....#',
        '...#..',
        '.##...',
        '#.....',
        '#.#..#',
    ],
    [    # After 5 steps:
        '##.###',
        '.##..#',
        '.##...',
        '.##...',
        '#.#...',
        '##...#',
    ],
];

is-deeply parse-state( @test-lights[0] ),
    [[0, 0, 0, 0, 0, 0, 0, 0],
     [0, 0, 1, 0, 1, 0, 1, 0],
     [0, 0, 0, 0, 1, 1, 0, 0],
     [0, 1, 0, 0, 0, 0, 1, 0],
     [0, 0, 0, 1, 0, 0, 0, 0],
     [0, 1, 0, 1, 0, 0, 1, 0],
     [0, 1, 1, 1, 1, 0, 0, 0],
     [0, 0, 0, 0, 0, 0, 0, 0]], "Correctly parsed test lights";

is-deeply count-lights( parse-state( @test-lights[0] ) ),
    15, "Correct number of test lights are on";

for ( @test-lights Z @test-lights[1..*] ).kv -> $i, $s {
    is-deeply next-state( parse-state( $s[0] ) ), parse-state( $s[1] ),
        "[$i] State is correct";
}

for ( @stuck-lights Z @stuck-lights[1..*] ).kv -> $i, $s {
    is-deeply next-stuck-state( parse-state( $s[0] ) ), parse-state( $s[1] ),
        "[$i] Stuck state is correct";
}

my @input = parse-state( "18-input".IO.lines );
my @stuck-input = @input;

for 1..100 {
    diag "Step $_";
    @input = next-state( @input );
    @stuck-input = next-stuck-state( @stuck-input );
}

is count-lights(@input),       821, "Correct number of lights are on";
is count-lights(@stuck-input), 886, "Correct number of stuck lights are on";

done-testing;
