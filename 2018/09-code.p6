#!perl6
use Test;

class Marble {
	has Int $!value;

	has Marble $.prev;
	has Marble $.next;

	submethod BUILD(
		:$!value,
		:$!prev = self,
		:$!next = self,
	) {}

	method Real    { $!value }
	method Numeric { $!value }

	method set-next( Marble $new ) { $!next = $new }
	method set-prev( Marble $new ) { $!prev = $new }

	method insert-after(Marble $marble) {
		$!prev = $marble;
		$!next = $marble.next;

		$marble.set-next( self );
		$!next.set-prev( self );

		return self;
	}

	method remove() {
		$!prev.set-next( $!next );
		$!next.set-prev( $!prev );

		my $next = $!next;

		$!next = $!prev = self;

		return $next;
	}
}

sub parse-rule($line) {
	my $m = $line ~~ m/
	    $<players> = \d+ " players"
	    "; last marble is worth " $<last-marble> = \d+ " points"
	  [ ": high score is " $<high-score> = \d+ ]?
	/;

	return {
		players     => $/<players>.Str,
		last-marble => $/<last-marble>.Str,
		high-score  => $/<high-score> ?? $/<high-score>.Str !! Nil,
	};

}

sub play-game(:$players, :$last-marble) {
	my @score[$players];

	my $player = 0;
	my $current = Marble.new( value => 0 );
	for (1..$last-marble).map({ Marble.new( value => $_ ) }) -> $marble {

		if $marble %% 23 {
			$current = $current.prev for ^7;
			@score[ $player ] += $marble + $current;
			$current = $current.remove;
		}
		else {
			$current = $marble.insert-after( $current.next );
		}

		$player++;
		$player %= $players;
	}

	return @score.max;
}

my @examples = q:to/EOL/.lines.map({ parse-rule($_) });
10 players; last marble is worth 1618 points: high score is 8317
13 players; last marble is worth 7999 points: high score is 146373
17 players; last marble is worth 1104 points: high score is 2764
21 players; last marble is worth 6111 points: high score is 54718
30 players; last marble is worth 5807 points: high score is 37305
EOL

#@examples.perl.say;

is play-game( players => 9, last-marble => 25 ), 32,
    "High score correct in short example";

for @examples.kv -> $i, %rules {
	is play-game(
	    players     => %rules<players>,
	    last-marble => %rules<last-marble>,
	), %rules<high-score>, "Example $i has expected high-score";
}

{
	my %rules = '09-input'.IO.lines.first.&parse-rule;

	is play-game(
	    players     => %rules<players>,
	    last-marble => %rules<last-marble>,
	), 361466, "Input has expected high-score";

	is play-game(
	    players     => %rules<players>,
	    last-marble => %rules<last-marble> * 100,
	), 2945918550, "Input with 100 * last-marble has expected high-score";

}


done-testing;
