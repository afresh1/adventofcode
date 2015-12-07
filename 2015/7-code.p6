#!/usr/local/bin/perl6
use v6;

use Test;

class Gate {
    has $.circuit;
    has $.wire is rw;
    has %.cache;

    my @subclasses;
    method register_subclass ( Gate $g ) { @subclasses.push( $g ) }

    multi method new ($c, Str $op) {
        for @subclasses -> $s {
            my $o = $s.new($c, $op);
            #say $s.^name ~ "\.new( $op ) = " ~ $o.^name;
            return $o if $o;
        }
        die "Invalid operation $op";
    }

    method debug (Str $s) {}# say $s }

    method reset () { %.cache = () }

    method connection (Str $w) { return $.circuit.connections{$w} }
    method Numeric (Numeric $v) { return $v +& 0xFFFF }
    method Str () { return $.wire // "0" }
}

class Circuit {
    has %.connections;

    method connect($i) {
        return unless $i.trim;

        if (my ($cmd, $wire) = split(" -> ", $i.trim)) {
            die "$wire already connected"
                if %.connections{$wire}:exists;
            %.connections{$wire} = Gate.new( self, $cmd );
            $.connections{$wire}.wire = $wire;
            return $.connections{$wire};
        }
    }

    method reset () { $_.reset for %.connections.values }

    method hash () {
        my %c = %.connections;
        %c{$_} = %c{$_}.Numeric for %c.keys;
        return %c;
    }
}

class Gate::SIGNAL is Gate {
    has Str $.signal;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ($op ~~ /^$<signal>=[\w+]$/) {
            return self.new( circuit => $c, signal => $/<signal>.Str );
        }
    }

    method Numeric () {
        return %.cache<signal> if %.cache<signal>:exists;

        my $s = $.signal ~~ /^\d+$/
            ?? $.signal.Int
            !! self.connection($.signal).Numeric;

        self.debug("SIGNAL $s");
        return %.cache<signal> = callwith $s;
    }
}

class Gate::AND is Gate {
    has Str $.l;
    has Str $.r;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ($op ~~ /^$<l>=[\w+] \s+ AND \s+ $<r>=[\w+]$/) {
            return self.new( circuit => $c, l => $/<l>.Str, r => $/<r>.Str );
        }
    }

    method Numeric () {
        return %.cache{$.l}{$.r} if %.cache{$.l}{$.r}:exists;

        my $l = $.l ~~ /^\d+$/ ?? $.l !! self.connection($.l);
        my $r = $.r ~~ /^\d+$/ ?? $.r !! self.connection($.r);
        self.debug("$r AND $l");
        return %.cache{$.l}{$.r} = callwith $l +& $r;
    }
}

class Gate::OR is Gate {
    has Str $.l;
    has Str $.r;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ($op ~~ /^$<l>=[\w+] \s+ OR \s+ $<r>=[\w+]$/) {
            return self.new( circuit => $c, l => $/<l>.Str, r => $/<r>.Str );
        }
    }

    method Numeric () {
        return %.cache{$.l}{$.r} if %.cache{$.l}{$.r}:exists;
        my $l = $.l ~~ /^\d+$/ ?? $.l !! self.connection($.l);
        my $r = $.r ~~ /^\d+$/ ?? $.r !! self.connection($.r);
        self.debug("$r OR $l");
        return %.cache{$.l}{$.r} = callwith $l +| $r;
    }
}

class Gate::NOT is Gate {
    has Str $.r;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ($op ~~ /^NOT \s+ $<r>=[\w+]$/) {
            return self.new( circuit => $c, r => $/<r>.Str );
        }
    }

    method Numeric () {
        my $r = $.r ~~ /^\d+$/ ?? $.r !! self.connection($.r);
        self.debug("NOT $r");
        return %.cache{$.r} = callwith +^$r;
    }
}

class Gate::LSHIFT is Gate {
    has Str $.l;
    has Str $.r;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ( $op ~~ /^$<l>=[\w+] \s+ LSHIFT \s+ $<r>=[\d+]$/ ) {
            return self.new( circuit => $c, l => $/<l>.Str, r => $/<r>.Str );
        }
    }

    method Numeric () {
        return %.cache{$.l}{$.r} if %.cache{$.l}{$.r}:exists;
        my $l = $.l ~~ /^\d+$/ ?? $.l !! self.connection($.l);
        my $r = $.r ~~ /^\d+$/ ?? $.r !! self.connection($.r);
        self.debug("$l LSHIFT $r");
        return %.cache{$.l}{$.r} = callwith $l +< $r;
    }
}

class Gate::RSHIFT is Gate {
    has Str $.l;
    has Str $.r;

    $?PACKAGE.register_subclass($?PACKAGE);

    multi method new ( Circuit $c, Str $op ) {
        if ( $op ~~ /^$<l>=[\w+] \s+ RSHIFT \s+ $<r>=[\d+]$/ ) {
            return self.new( circuit => $c, l => $/<l>.Str, r => $/<r>.Str );
        }
    }

    method Numeric () {
        return %.cache{$.l}{$.r} if %.cache{$.l}{$.r}:exists;
        my $l = $.l ~~ /^\d+$/ ?? $.l !! self.connection($.l);
        my $r = $.r ~~ /^\d+$/ ?? $.r !! self.connection($.r);
        return 0 if $l == 0;
        self.debug("$l RSHIFT $r");
        return %.cache{$.l}{$.r} = callwith $l +> $r;
    }
}

subtest {
    my $t = q{
        x AND y -> d
        123 -> x
        x LSHIFT 2 -> f
        NOT x -> h
        y RSHIFT 2 -> g
        456 -> y
        NOT y -> i
        x OR y -> e
    };

    my $c = Circuit.new;
    $c.connect($_) for $t.split("\n");

    is-deeply $c.hash, {
        d =>  72,
        e =>  507,
        f =>  492,
        g =>  114,
        h =>  65412,
        i =>  65079,
        x =>  123,
        y =>  456,
    };
}, "Test Code";

subtest {
    my $c = Circuit.new;
    for "7-input".IO.lines -> $l {
        #say $l;
        $c.connect($l);
    }
    my $a = $c.connections<a>.Numeric;
    is $a, 16076, "First, a is 16,076";

    $c.reset;
    $c.connections<b> = Gate::SIGNAL.new(
        circuit => $c,
        signal  => $a.Str,
    );
    is $c.connections<a>.Numeric, 2797, "Then a is 2,797";
}, "Input";

done-testing;
