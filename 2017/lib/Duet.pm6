class Duet {
    has Int $.i = 0;
    has @!instructions;

    has Int %!registers is default(0);
    has Int $.sound;

    submethod BUILD(:@!instructions) {}

    multi method snd(Str $v) { self.snd( %!registers{$v} ) }
    multi method snd(Int $v) { $!sound = $v }

    multi method set(Str $r, Str $v) { self.set( $r, %!registers{$v} ) }
    multi method set(Str $r, Int $v) { %!registers{$r} = $v }
    multi method add(Str $r, Str $v) { self.add( $r, %!registers{$v} ) }
    multi method add(Str $r, Int $v) { %!registers{$r} += $v }
    multi method mul(Str $r, Str $v) { self.mul( $r, %!registers{$v} ) }
    multi method mul(Str $r, Int $v) { %!registers{$r} *= $v }
    multi method mod(Str $r, Str $v) { self.mod( $r, %!registers{$v} ) }
    multi method mod(Str $r, Int $v) { %!registers{$r} %= $v }

    multi method rcv(Str $v) { self.rcv( %!registers{$v} ) }
    multi method rcv(Int $v) { $v == 0 ?? Nil !! $!sound }

    multi method jgz(Str $x, Str $y) {
        self.jgz( %!registers{$x}, %!registers{$y} );
    }
    multi method jgz(Str $x, Int $y) { self.jgz( %!registers{$x}, $y ) }
    multi method jgz(Int $x, Str $y) { self.jgz( $x, %!registers{$y} ) }
    multi method jgz(Int $x, Int $y) { $!i += ( $y - 1 ) if $x > 0 }

    method process() {
        my %instruction = @!instructions[$!i];
        #%instruction.say;

        my $m = %instruction<instruction>;
        $!i++;

        return( $m, self."$m"( |%instruction<args>.cache ) );
    }

    method gist() { %!registers.gist }
}
