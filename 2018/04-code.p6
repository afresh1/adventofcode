#!perl6
use Test;

my $current_guard;
my %guards;

# [1518-11-01 00:00] Guard #10 begins shift
# [1518-11-01 00:05] falls asleep
# [1518-11-01 00:25] wakes up
grammar LogLine {
	token TOP { '[' <ts> '] ' <status> }

	token ts  { <year> '-' <month> '-' <day> ' ' <hour> ':' <minute> }
	token year   { \d ** 4 }
	token month  { \d ** 2 }
	token day    { \d ** 2 }
	token hour   { \d ** 2 }
	token minute { \d ** 2 }

	token status { <guard> | <asleep> | <awake> }
	token guard  { 'Guard #' <id> ' begins shift' }
	token id     { \d+ }
	token asleep { 'falls asleep' }
	token awake  { 'wakes up'     }
}

for '04-input'.IO.lines.sort.map({ LogLine.parse($_) }) -> $l {
	if $l<status><guard> {
		$current_guard = $l<status><guard><id>;
	}
	elsif $current_guard {
		my $status
		  = $l<status><asleep> ?? 'asleep'
                 !! $l<status><awake>  ?? 'awake'
                 !! die "Unable to guess status from $l";

		my $date = $l<ts>< year month day >.join('-');
		%guards{ $current_guard }{$date}[ $l<ts><minute> ]
		    = $status;
	}
	else {
		die "Unable to understand $l";
	}
}

my %asleep;
for %guards.keys -> $id {
	for %guards{$id}.keys -> $date {
		my $status = '';
		for '00' .. '59' -> $m {
			if %guards{$id}{$date}[$m].defined {
				$status = %guards{$id}{$date}[$m];
			}
			%asleep{$id}[$m] ||= 0;
			%asleep{$id}[$m]++ if $status eq 'asleep';
		}
	}
}

{
	my ( $guard, $when ) = %asleep.max({ .value.sum }).kv;
	my $minute = $when.pairs.max({.value}).key;
	is $guard * $minute, 48680, "Most asleep guard";
}

{
	my ( $guard, $when ) = %asleep.max({ .value.max }).kv;
	my $minute = $when.pairs.max({.value}).key;
	is $guard * $minute, 94826, "Most asleep at the same time guard";

}


done-testing;
