#!/usr/local/bin/perl6
use v6;
use Test;

class Effect {
    has Str $.name;
    has Int $.mana   = 0;
    has Int $.damage = 0;
    has Int $.heal   = 0;
    has Int $.armor  = 0;
    has Int $.effect is rw = 1;

    method apply () {
        $.effect--;
        return self.hash;
    }

    method hash () {
        mana  => $.mana,
        hp    => $.heal - $.damage,
        armor => $.armor,
    }

}

class Spell {
    has Str $.name;
    has Int $.cost   = 0;
    has Int $.mana   = 0;
    has Int $.damage = 0;
    has Int $.heal   = 0;
    has Int $.armor  = 0;
    has Int $.effect = 1;

    method cast () {
        my $good = Effect.new(
            :effect( $.effect ),
            :mana( $.mana ),
            :heal( $.heal ),
            :armor( $.armor ),
        );

        my $bad = Effect.new(
            :effect( $.effect ),
            :damage( $.damage ),
        );

        return ($good, $bad);
    }

    method hash ( --> Hash ) {
        return {
            name   => $.name,
            mana   => $.mana,
            damage => $.damage,
            heal   => $.heal,
            armor  => $.armor,
            effect => $.effect,
        }
    }
}

class Spellbook {
    has Spell @.spells;

    method study (Str $name) { @.spells.first({ .name eq $name }) }
}

class Character {
    has Int %.stats is rw;
    has Effect @.effects;

    method add-effect (Effect $effect) {
        %.stats<armor> += $effect.armor if $effect.armor;
        @.effects.push($effect);
    }

    method feel-effects () {
        for @.effects -> $e {
            my %changes = $e.apply;
            for %changes.kv -> $what, $how_much {
                if $what eq 'armor' {
                    %.stats<armor> -= $how_much
                        if $how_much and $e.effect == 0;
                }
                elsif $how_much {
                    %.stats{$what} += $how_much;
                }
            }
        }

        @.effects = @.effects.grep({ .effect > 0 });
    }

    method take-damage (Int $damage) {
        %.stats<hp> = max( %.stats<hp> - $damage, 0);
    }

    method attack ($defender) {
        my $damage = self.damage - $defender.armor;
        $damage = 1 if $damage < 1;
        $defender.take-damage( $damage );
    }

    method is-dead () { $.hp < 1 }

    method hp     () { $.stats<hp>     || 0 }
    method damage () { $.stats<damage> || 0 }
    method armor  () { $.stats<armor>  || 0 }
}

class Monster is Character { }

class Spellcaster is Character {
    has Spellbook $.spellbook;

    has Int $.spent-mana is rw = 0;

    method cast(Str $name, Character $other) {
        my $spell = $.spellbook.study($name);

        %.stats<mana> -= $spell.cost;
        $.spent-mana += $spell.cost;

        my ($good, $bad) = $spell.cast;

        $.stats<armor> += $good<armor> if $good<armor>;
        self.add-effect( $good );
        $other.add-effect( $bad );
    }

    method mana () { $.stats<mana> || 0 }
}

class Arena {
    has Character $.player;
    has Character $.boss;

    method fight (Str $spell = '') {
        .feel-effects for $.player, $.boss;
        return True if $.boss.is-dead or $.player.is-dead;

        $.player.cast($spell, $.boss) if $spell;
        return True if $.boss.is-dead or $.player.is-dead;

        .feel-effects for $.player, $.boss;
        return True if $.boss.is-dead or $.player.is-dead;

        $.boss.attack( $.player );
        return False;
    }
}

my $book = Spellbook.new( spells => [
    Spell.new( :name('Magic Missile'), :cost(53), :damage(4) ),
    Spell.new( :name('Drain'), :cost(73), :damage(2), :heal(2) ),
    Spell.new( :name('Shield'), :cost(113), :effect(6), :armor(7) ),
    Spell.new( :name('Poison'), :cost(173), :effect(6), :damage(3) ),
    Spell.new( :name('Recharge'), :cost(229), :effect(5), :mana(101) ),
]);

my %boss-stats = "22-input".IO.lines.map({
    my ($k, $v) = .lc.split(': ');
    $k = 'hp' if $k eq 'hit points';
    $k => $v.Int;
});

subtest {
    my $arena = Arena.new(
        :player(Spellcaster.new( :stats( :hp(10), :mana(250) ), :spellbook($book) ) ),
        :boss(  Monster.new( :stats( :hp(13), :damage(8) ) ) ),
    );

    $arena.fight('Poison');

    is-deeply $arena.player.stats, { hp =>  2, mana => 77 },
        "Player is down to two HP and 77 mana";

    is-deeply $arena.boss.stats, { hp => 10, damage => 8 },
    "Boss has 10 HP";

    $arena.fight('Magic Missile');;

    is-deeply $arena.player.stats, { hp =>  2, mana => 24 },
        "Player is down to two HP and 24 mana";

    is-deeply $arena.boss.stats, { hp => 0, damage => 8 },
        "Boss has 0 HP";
}, "First Test Arena";

subtest {
    my $arena = Arena.new(
        :player(Spellcaster.new( :stats( :hp(10), :mana(250) ), :spellbook($book) ) ),
        :boss(  Monster.new( :stats( :hp(14), :damage(8) ) ) ),
    );

    $arena.fight('Recharge');

    is-deeply $arena.player.stats, { hp =>  2, mana => 122 },
        "Round One: Player";

    is-deeply $arena.boss.stats, { hp => 14, damage => 8 },
        "Round One: Boss";

    $arena.fight('Shield');

    is-deeply $arena.player.stats,
        { hp =>  1, armor => 7, mana => 211 },
        "Round Two Player";

    is-deeply $arena.boss.stats, { hp => 14, damage => 8 },
        "Round Two Boss";

    $arena.fight('Drain');

    is-deeply $arena.player.stats,
        { hp =>  2, armor => 7, mana => 340 },
        "Round Three Player";

    is-deeply $arena.boss.stats, { hp => 12, damage => 8 },
        "Round Three Boss";

    $arena.fight('Poison');

    is-deeply $arena.player.stats,
        { hp =>  1, armor => 7, mana => 167 },
        "Round Four Player";

    is-deeply $arena.boss.stats, { hp => 9, damage => 8 },
        "Round Four Boss";

    $arena.fight('Magic Missile');

    is-deeply $arena.player.stats,
        { hp =>  1, armor => 0, mana => 114 },
        "Round Five Player";

    is-deeply $arena.boss.stats, { hp => -1, damage => 8 },
        "Round Five Boss";

}, "Second Test Arena";



subtest {

    sub battle (@spells, $next) {
        my $arena = Arena.new(
            :player(Spellcaster.new( :stats(
                :hp(50), :mana(500) ), :spellbook($book) ) ),
            :boss(  Monster.new( :stats(|%boss-stats) ) ),
        );

        my $p := $arena.player;

        # Replay the fight that got us here
        $arena.fight($_) for @spells;

        # If we ended up running out of mana, we can't cast
        # any spells, but we might win.
        #1 while !$p.is-dead and $p.mana < $next.cost and not $arena.fight;
#                say "Boss: "      ~ $arena.boss.hp
#                    ~ " Player: " ~ $p.hp
#                    ~ " mana "    ~ $p.mana
#                    ~ " Trying "  ~ @try.gist;

        my $outcome = False;
        $outcome = $arena.fight($next.name)
            if !$p.is-dead and $p.mana >= $next.cost;

        return ( $outcome, $p.spent-mana, $p.stats );
    }

    # 1415 is a winner, but too high
    multi sub battle-combinations ( @spells = [], $spent = 0, $b = 0 ) {
        my @winners;
        my $best = $b;

        for $book.spells.pick(*) -> $next {
            next if $best and $spent + $next.cost > $best;

            my ($outcome, $spent-mana, %stats) = battle(@spells, $next);
            my @try = ( |@spells, $next.name );

            if ($outcome) {
                $best = $spent-mana if $best == 0 or $best > $spent-mana;
                say "Winner! " ~ $spent-mana ~ " $best " ~ @try.gist;
                #@winners.push( @try );
            }
            elsif (%stats<hp> > 0) {
                #say "Continuing to " ~ @try;
                my ($b, @w) = battle-combinations(
                    @try, $spent-mana, $best );

                $best = $b if $b and ( $best == 0 or $best > $b );
                #@winners.append( @w )
            }
            else {
                say "Loser! " ~ $spent-mana ~ " $best " ~ @try.gist;
            }

        }

        return ( $best, @winners );
    }

    my ( $best, @winners ) = battle-combinations();
    say @winners.gist;
    say "Best: $best";


}, "First Challenge";


done-testing;
