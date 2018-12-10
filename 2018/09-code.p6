#!perl6
use Test;

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
	my @board  = 0;
	for 1..$last-marble -> $marble {
		if $marble %% 23 {
			@board = @board.rotate(-7);

			my $prev = @board.pop.sum;
			@score[ $player ] += $marble + $prev;
			@board = @board.rotate;
		}
		else {
			@board = @board.rotate;
			@board.push($marble);
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
