#!/usr/local/bin/perl6
use v6;
use Test;

sub load_cities ($d) {
    my %directions;
    my %cities;
    for $d.flat {
        / $<start>=[\w+] \s+ to \s+ $<end>=[\w+] \s+ \= \s+ $<distance>=[\d+] /;
        %directions{$/<start>}{$/<end>} = $/<distance>.Int;
        %cities{$/<start>, $/<end>} = (1, 1);
    }
    return { :cities( %cities.keys ), :directions( %directions ) };
}

sub distances ($d) {
    my %c = load_cities($d);
    my %directions;

    for %c.<cities>.permutations
      .grep({ not %directions{ .reverse.join(" -> ") } }) {
        my $k = .join(" -> ");
        my $v = 0;

        my ($start, @c) = $_.flat;
        while (@c) {
            my $end = @c.shift;

            $v += %c<directions>{$start}{$end}
                || %c<directions>{$end}{$start};

            $start = $end;
        }

        %directions{$k} = $v;
    }

    return %directions;
}

sub distances_concurrent ($d) {
    my %c = load_cities($d);

    my $channel = Channel.new;
    my %seen;
    await %c.<cities>.permutations.grep({
        if (%seen{ $_.reverse.join(" -> ") }) {
            False;
        }
        else {
            %seen{ $_.join(" -> ") } = 1;
            True;
        }
    }).race.map: {
        start {
            my $k = .join(" -> ");
            my $v = 0;

            my ($start, @c) = $_.flat;
            while (@c) {
                my $end = @c.shift;

                $v += %c<directions>{$start}{$end}
                    || %c<directions>{$end}{$start};

                $start = $end;
            }

            $channel.send( $k => $v );
        }
    }

    $channel.close;
    return $channel.hash;
}

subtest {
    my @directions = (
        'London to Dublin = 464',
        'London to Belfast = 518',
        'Dublin to Belfast = 141',
    );

    my %d = distances(@directions);
    is %d.values.min, 605, "Min distance is 605";
    is %d.values.max, 982, "Max distance is 982";
}, "Test Distance";

subtest {
    my %d = distances("9-input".IO.lines);
    is %d.values.min, 207, "Min distance is 207";
    is %d.values.max, 804, "Max distance is 804";
}, "Input Distance";

subtest {
    my @directions = (
        'London to Dublin = 464',
        'London to Belfast = 518',
        'Dublin to Belfast = 141',
    );

    my %d = distances_concurrent(@directions);
    is %d.values.min, 605, "Min distance is 605";
    is %d.values.max, 982, "Max distance is 982";
}, "Test Distance Concurrent";

subtest {
    my %d = distances_concurrent("9-input".IO.lines);
    is %d.values.min, 207, "Min distance is 207";
    is %d.values.max, 804, "Max distance is 804";
}, "Input Distance Concurrent";

done-testing;
