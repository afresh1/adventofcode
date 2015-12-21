#!/usr/local/bin/perl6
use v6;
use Test;

class Store {
    has %.aisles;

    multi method new (Str $store) {
        my %parsed;
        my $section;

        for $store.lines -> $l {
            my ($name, $cost, $damage, $armor) = $l.split(/\s+/);
            if ($name ~~ s/\:$//) {
                $section = $name;
            }
            elsif ($section and $name) {
                %parsed{$section}.push({
                    name    => $name,
                    cost    => $cost.Int,
                    damage  => $damage.Int,
                    armor   => $armor.Int,
                });
            }
        }

        return self.new(:aisles(%parsed));
    }

    method options () {
        my %requirements = (
            :Weapons(1),
            :Armor(0,1),
            :Rings(0,1,2),
        );

        my %options;

        for %.aisles.kv -> $section, @items {
            %options{$section} = %requirements{$section}.flat.map({
                    |@items.combinations($_).list }).list;
        }

        my @options;

        for %options<Weapons>.list -> @weapons {
            for %options<Armor>.list -> @armor {
                for %options<Rings>.list -> @rings {
                    my %stats;
                    my @name;
                    for ( |@weapons, |@armor, |@rings ) -> %item {
                        @name.push( %item<name> ) if %item<name>:exists;
                        %stats{$_} += %item{$_} for < cost damage armor >;
                    }
                    %stats<name> = @name.join(", ");

                    @options.push(%stats);
                }
            }
        }

        return @options;
    }
}

class Character {
    has Int $.hp is rw;
    has Int $.damage;
    has Int $.armor;

    method take-damage (Int $hp) {
        $.hp -= $hp;
        $.hp = 0 if $.hp < 0;
    }

    method attack ($defender) {
        my $damage = self.damage - $defender.armor;
        $damage = 1 if $damage < 1;
        $defender.take-damage( $damage );
    }
}

class Arena {
    has Character $.player;
    has Character $.boss;

    method fight () {
        $.player.attack($.boss);

        return if $.boss.hp == 0;

        $.boss.attack( $.player );
    }

    method battle () {
        self.fight() while $.boss.hp > 0 and $.player.hp > 0;
        return 'player' if $.player.hp > 0;
        return 'boss';
    }
}

my $store = Store.new(q{
Weapons:    Cost  Damage  Armor
Dagger        8     4       0
Shortsword   10     5       0
Warhammer    25     6       0
Longsword    40     7       0
Greataxe     74     8       0

Armor:      Cost  Damage  Armor
Leather      13     0       1
Chainmail    31     0       2
Splintmail   53     0       3
Bandedmail   75     0       4
Platemail   102     0       5

Rings:      Cost  Damage  Armor
Damage_+1    25     1       0
Damage_+2    50     2       0
Damage_+3   100     3       0
Defense_+1   20     0       1
Defense_+2   40     0       2
Defense_+3   80     0       3
});

#say $store.aisles.perl; exit;

my $test-arena = Arena.new(
    :player(Character.new( :hp( 8), :damage(5), :armor(5) )),
    :boss(  Character.new( :hp(12), :damage(7), :armor(2) )),
);


$test-arena.fight;
is $test-arena.boss.hp, 9,
    'The player deals 5-2 = 3 damage; the boss goes down to 9 hit points.';
is $test-arena.player.hp, 6,
    'The boss deals 7-5 = 2 damage; the player goes down to 6 hit points.';

$test-arena.fight;
is $test-arena.boss.hp, 6,
    'The player deals 5-2 = 3 damage; the boss goes down to 6 hit points.';
is $test-arena.player.hp, 4,
    'The boss deals 7-5 = 2 damage; the player goes down to 4 hit points.';

$test-arena.fight;
is $test-arena.boss.hp, 3,
    'The player deals 5-2 = 3 damage; the boss goes down to 3 hit points.';
is $test-arena.player.hp, 2,
    'The boss deals 7-5 = 2 damage; the player goes down to 2 hit points.';

$test-arena.fight;
is $test-arena.boss.hp, 0,
    'The player deals 5-2 = 3 damage; the boss goes down to 0 hit points.';

my %boss_stats = ( :hp(100), :damage(8), :armor(2) );
my @options = $store.options.sort({ %^a<cost> <=> %^b<cost> });

my %least;
my %most;
for @options -> %stats {
    my $arena = Arena.new(
        :player( Character.new( :hp(100), |%stats ) ),
        :boss(   Character.new( |%boss_stats ) ),
    );

    my $winner = $arena.battle;
    if ($winner eq 'player') {
        %least = %stats unless %least;
    }
    else {
        %most = %stats;
    }
}

is %least<cost>, 91, "Least cost is 91";
is %most<cost>, 158, "Most cost is 158 (that cheating shopkeeper!)";

done-testing;
