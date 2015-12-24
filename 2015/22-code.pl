#!/usr/bin/perl
use v5.20;
use warnings;

use experimental 'signatures';

use Storable qw( dclone );
use Test::More;

my @player_order = qw( player boss );
my %spells = (
    'Magic Missile' => { cost => 53,  damage => 4 },
    'Drain'         => { cost => 73,  damage => 2, heal => 2 },
    'Shield'        => { cost => 113, effect => 6, armor => 7 },
    'Poison'        => { cost => 173, effect => 6, damage => 3 },
    'Recharge'      => { cost => 229, effect => 5, mana => 101 },
);


subtest "First Test Arena" => sub {
    my $arena = {
        player => { stats => { hp => 10, mana   => 250 }, effects => [] },
        boss   => { stats => { hp => 13, damage => 8 },   effects => [] },
    };

    my $player = $arena->{player};
    my $boss   = $arena->{boss};

    fight($arena, 'Poison');

    is_deeply $player->{stats}, { hp =>  2, mana => 77 },
        "Round One Player";

    is_deeply $boss->{stats}, { hp => 10, damage => 8 },
        "Round One Boss";

    fight($arena, 'Magic Missile');

    is_deeply $player->{stats}, { hp =>  2, mana => 24 },
        "Round Two Player";

    is_deeply $boss->{stats}, { hp => 0, damage => 8 },
        "Round Two Boss";
};


subtest "Second Test Arena" => sub {
    my $arena = {
        player => { stats => { hp => 10, mana   => 250 }, effects => [] },
        boss   => { stats => { hp => 14, damage => 8 },   effects => [] },
    };

    my $player = $arena->{player};
    my $boss   = $arena->{boss};

    fight($arena, 'Recharge');

    is_deeply $player->{stats}, { hp =>  2, mana => 122 },
        "Round One Player";

    is_deeply $boss->{stats}, { hp => 14, damage => 8 },
        "Round One Boss";

    fight($arena, 'Shield');

    is_deeply $player->{stats},
        { hp =>  1, armor => 7, mana => 211 },
        "Round Two Player";

    is_deeply $boss->{stats}, { hp => 14, damage => 8 },
        "Round Two Boss";

    fight($arena, 'Drain');

    is_deeply $player->{stats},
        { hp =>  2, armor => 7, mana => 340 },
        "Round Three Player";

    is_deeply $boss->{stats}, { hp => 12, damage => 8 },
        "Round Three Boss";

    fight($arena, 'Poison');

    is_deeply $player->{stats},
        { hp =>  1, armor => 7, mana => 167 },
        "Round Four Player";

    is_deeply $boss->{stats}, { hp => 9, damage => 8 },
        "Round Four Boss";

    fight($arena, 'Magic Missile');

    is_deeply $player->{stats},
        { hp =>  1, armor => 0, mana => 114 },
        "Round Five Player";

    is_deeply $boss->{stats}, { hp => -1, damage => 8 },
        "Round Five Boss";
};


subtest "Grr" => sub {
    my $arena = {
        player => { stats => { hp => 50, mana => 500 }, effects => [] },
        boss => { stats => { hp => 58, damage => 9 }, effects => [] },
    };

    my $player = $arena->{player};
    my $boss   = $arena->{boss};

     my @best = qw(
        Poison
        Recharge
        Shield
        Poison
        Recharge
        Shield
        Poison
    );
    push @best, 'Magic Missile';
    push @best, 'Magic Missile';

    foreach my $spell (@best) {
        fight( $arena, $spell );
    }

    is_deeply $player->{stats}, { hp =>  20, armor => 0, mana => 201 },
        "Player";

    is_deeply $boss->{stats}, { hp => -1, damage => 9 },
        "Boss";

    is $player->{spent_mana}, 1309;
};

open my $fh, '<', '22-input' or die $!;
my %boss_stats = map {
    chomp;
    my ( $k, $v ) = map {lc} split(': ');
    $k = 'hp' if $k eq 'hit points';
    $k => $v;
} readline($fh);
close $fh;

subtest "Real Test" => sub {
    my %arena = (
        player => { stats => { hp => 50, mana => 500 }, effects => [] },
        boss => { stats => \%boss_stats, effects => [] },
    );

    is battle( \%arena ), 1269;
};

subtest "Hard Test" => sub {
    my %arena = (
        player => { stats => { hp => 50, mana => 500 }, effects => [] },
        boss => { stats => \%boss_stats, effects => [] },
        hard => 1,
    );

    is battle( \%arena ), 1309;
};

sub battle ($arena, $b = 0) {
    my $best = $b;
    foreach my $spell_name (keys %spells) {
        if ($best) {
            my $spent_mana = $arena->{player}->{spent_mana} || 0;
            next if $best < $spent_mana + $spells{$spell_name}{cost};
        }

        my $try = dclone($arena);
        push @{ $try->{spells} }, $spell_name;

        my $result = fight( $try, $spell_name );
        my $spent_mana = $try->{player}->{spent_mana} || 0;
        my $php = $try->{player}->{stats}->{hp};
        my $bhp = $try->{boss}->{stats}->{hp};

        if ( $bhp <= 0 ) {
            $best = $spent_mana if $best == 0 or $best > $spent_mana;
            say "Winner! [$spent_mana] [$php] [$bhp] @{ $try->{spells} }";

        }
        elsif ( $result and $php > 0 ) {
            my $b = battle($try, $best);
            $best = $b if $best == 0 or $best > $b;
        }
        else {
            say "Loser! [$spent_mana] [$php] [$bhp] @{ $try->{spells} }";
        }
    }
    return $best;
}

sub in_effect ($player, $spell_name) {
    my @effects = @{ $player->{effects} || [] };

    foreach my $effect (@effects) {
        return 1 if $effect->{name} eq $spell_name;
    }

    return;
}

sub fight ($arena, $spell_name) {
    my $p = $arena->{player};
    my $b = $arena->{boss};

    foreach my $e (@{ $p->{effects} || [] }) {
        next unless $e->{name} eq $spell_name;
        return if $e->{effect} > 1;
    }

    if (my $hard = $arena->{hard}) {
        $p->{stats}->{hp} -= $hard;
        return if $p->{stats}->{hp} <= 0;
    }

    feel_effects($arena) or return;
    attack( $p, $b, $spell_name ) or return;

    feel_effects($arena) or return;
    attack( $b, $p ) or return;

    return 1;
}

sub attack ($attacker, $defender, $spell_name = '') {
    my $damage = 0;
    if (my $mana = $attacker->{stats}->{mana}) {
        my $spell = $spells{$spell_name};
        return if $mana < $spell->{cost}; # lose

        my ($good, $bad) = cast( $spell_name );

        $attacker->{spent_mana}    += $spell->{cost};
        $attacker->{stats}->{mana} -= $spell->{cost};

        $attacker->{stats}->{armor} += $good->{stats}->{armor}
            if $good->{stats}->{armor};

        $attacker->{stats}->{hp} += $good->{stats}->{hp}
            if $good->{stats}->{hp};

        if (my $damage = $bad->{stats}->{hp} and not $bad->{effect} ) {
            $defender->{stats}->{hp} += $damage; # add negative hp
        }

        push @{ $attacker->{effects} }, $good if $good->{effect};
        push @{ $defender->{effects} }, $bad  if $bad->{effect};
    }
    elsif (my $damage = $attacker->{stats}->{damage}) {
        $damage -= $defender->{stats}->{armor} || 0;
        $damage = 1 if $damage < 1;
        $defender->{stats}->{hp} -= $damage;
    }
    else {
        say "Sitting this turn out";
        return;
    }

    return $defender->{stats}->{hp} >= 0;
}

sub cast ($spell_name) {
    my $spell = $spells{$spell_name};
    my $effect = $spell->{effect};
    my %good = (
        name   => $spell_name,
        effect => $effect,
        stats  => {
            map { $_ => $spell->{$_} }
            grep { exists $spell->{$_} } qw( armor mana )
        }
    );
    $good{stats}{hp} = $spell->{heal} if exists $spell->{heal};

    my %bad;
    %bad = (
        name   => $spell_name,
        effect => $effect,
        stats  => { hp => 0 - $spell->{damage} }
    ) if exists $spell->{damage};

    return ( \%good, \%bad );
}

sub feel_effects ($arena) {
    foreach my $name (@player_order) {
        _feel_effects( $arena->{$name} ) || return;
    }
    return 1;
}

sub _feel_effects ($player) {
    my @still_effective;
    foreach my $e (@{ $player->{effects} }) {
        $e->{effect}--;

        foreach my $name ( keys %{ $e->{stats} } ) {
            my $value = $e->{stats}->{$name};
            if ( $name eq 'armor' ) {
                $player->{stats}->{armor} -= $value
                    if $value and $e->{effect} <= 0;
            }
            else {
                $player->{stats}->{$name} += $value;
            }
        }

        push @still_effective, $e if $e->{effect} > 0;
    }
    @{ $player->{effects} } = @still_effective;

    return $player->{stats}->{hp} > 0;
}

done_testing;
