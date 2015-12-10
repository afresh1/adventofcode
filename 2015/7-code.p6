#!/usr/local/bin/perl6
use v6;

use Test;

class X::Constructor::Gate::InvalidOp is Exception {
    has Str $.op;
    method message () { return "Invalid op $.op" }
}

class Gate {
    has $.circuit;
    has $.wire is rw;
    has %.cache;
    my Regex $.re;
    has %.args;

    my @subclasses;
    method register_subclass ( Gate $g ) { @subclasses.push( $g ) }

    # I want this signature to be (Circuit $c, Str $op)
    # but Circuit hasn't been declared yet and I don't know how.
    multi method new ($c, Int $op) { self.new( $c, $op.Str ) }
    multi method new ($c, Str $op) {
        if ($.re.defined) {
            if ($op ~~ $.re) {
                my %args = $/.hash;
                %args{$_} = %args{$_}.Str for %args.keys;
                return self.new( circuit => $c, args => %args );
            }
        }
        elsif (@subclasses) {
            for @subclasses -> $s {
                my $gate = $s.new($c, $op);
                #say $s.^name ~ "\.new( $op ) = " ~ $gate.^name;
                CATCH { when X::Constructor::Gate::InvalidOp { next } }
                return $gate;
            }
        }
        die X::Constructor::Gate::InvalidOp.new(:op($op));
    }

    method debug (Str $s) {}# say $s }

    method reset () { %.cache = () }

    method connection (Str $w) {
        return $w.Numeric if $w ~~ /^\d+$/;
        return $.circuit.connections{$w};
    }
    method Numeric (Numeric $v) { return $v +& 0xFFFF }
    method Str () {
        return self.WHICH ~~ self.^name
            ?? self.^name !! $.wire // "0";
    }
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
    my Regex $.re = rx/^$<signal>=[\w+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        return %.cache<signal> if %.cache<signal>:exists;

        my $s = self.connection(%.args<signal>).Numeric;

        self.debug("SIGNAL $s");
        return %.cache<signal> = callwith $s;
    }
}

class Gate::AND is Gate {
    my $.re = rx/^$<l>=[\w+] \s+ AND \s+ $<r>=[\w+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        my ($al, $ar) = %.args< l r >;
        return %.cache{$al}{$ar} if %.cache{$al}{$ar}:exists;

        my $l = self.connection($al);
        my $r = self.connection($ar);

        self.debug("$r AND $l");
        return %.cache{$al}{$ar} = callwith $l +& $r;
    }
}

class Gate::OR is Gate {
    my $.re = rx/^$<l>=[\w+] \s+ OR \s+ $<r>=[\w+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        my ($al, $ar) = %.args.< l r >;
        return %.cache{$al}{$ar} if %.cache{$al}{$ar}:exists;

        my $l = self.connection($al);
        my $r = self.connection($ar);

        self.debug("$r OR $l");
        return %.cache{$al}{$ar} = callwith $l +| $r;
    }
}

class Gate::NOT is Gate {
    my $.re = rx/^NOT \s+ $<r>=[\w+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        my $ar = %.args.<r>;
        return %.cache{$ar} if $.cache{$ar}:exists;

        my $r =  self.connection($ar);

        self.debug("NOT $r");
        return %.cache{$ar} = callwith +^$r;
    }
}

class Gate::LSHIFT is Gate {
    my $.re = rx/^$<l>=[\w+] \s+ LSHIFT \s+ $<r>=[\d+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        my ($al, $ar) = %.args.< l r >;
        return %.cache{$al}{$ar} if %.cache{$al}{$ar}:exists;

        my $l = self.connection($al);
        my $r = self.connection($ar);

        self.debug("$l LSHIFT $r");
        return %.cache{$al}{$ar} = callwith $l +< $r;
    }
}

class Gate::RSHIFT is Gate {
    my $.re = rx/^$<l>=[\w+] \s+ RSHIFT \s+ $<r>=[\d+]$/;
    $?PACKAGE.register_subclass($?PACKAGE);

    method Numeric () {
        my ($al, $ar) = %.args.< l r >;
        return %.cache{$al}{$ar} if %.cache{$al}{$ar}:exists;

        my $l = self.connection($al);
        my $r = self.connection($ar);

        self.debug("$l RSHIFT $r");
        return %.cache{$al}{$ar} = callwith $l +> $r;
    }
}


subtest {
    my %ops = (
        "Foo Bar"    => Gate,
        "123"        => Gate::SIGNAL,
        "x"          => Gate::SIGNAL,
        "x AND y"    => Gate::AND,
        "x OR y"     => Gate::OR,
        "NOT x"      => Gate::NOT,
        "x LSHIFT 2" => Gate::LSHIFT,
        "y RSHIFT 4" => Gate::RSHIFT,
    );
    my $c = Circuit.new;

    for %ops.kv -> $op, $gate {
        for %ops.values.unique -> $g {
            if (
                ( $g.^name eq 'Gate' and $g.^name ne $gate.^name )
                    or
                ( $g.^name ne 'Gate' and $g.^name eq $gate.^name )
            ) {
                lives-ok { $g.new($c, $op) }, "[$g] lives with $op";
            }
            else {
                throws-like { $g.new($c, $op) },
                    X::Constructor::Gate::InvalidOp,
                        "[$g] throws error for $op";
            }
        }
    }
}, "Gate Exceptions";

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
    $c.connections<b> = Gate::SIGNAL.new( $c, $a.Str );
    is $c.connections<a>.Numeric, 2797, "Then a is 2,797";
}, "Input";

done-testing;
