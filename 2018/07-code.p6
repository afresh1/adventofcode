#!perl6
use Test;

sub read-depends(@input) {
	my $match
	    = rx:s/Step (\w) must be finished before step (\w) can begin\./;
	return @input.map: { $/[1].Str => $/[0].Str if $_ ~~ $match };
}

sub to-deps(@in) {
	my %dep is default(Array);
	for @in.sort -> $r {
		%dep{$r.key}.push($r.value.Str);
		%dep{$r.value} ||= [];
	}
	return %dep;
}

sub tsort(@in) {
	my %dep = to-deps(@in);

	my sub _tsort( @d, %v = {} ) {
		my @r;
		for @d -> $i {
			next if %v{$i};
			%v{$i} = True;

			@r.append(|_tsort( %dep{$i}, %v ), $i )

		}
		return @r;
	}

	return _tsort(%dep.keys.sort);
}

sub dep-sort(@in) {
	my %dep = to-deps(@in);
	my @sorted;

	while %dep {
		for %dep.keys.sort -> $step {
			if %dep{$step} (<=) @sorted {
				%dep{$step}:delete;
				@sorted.append($step);
				last; # start over in order
			}
		}
	}
	return @sorted;
}

sub job-queue(@in, $step-time = 0, $worker_count = 2) {
	my %dep = to-deps(@in);
	my @workers[$worker_count];

	my %time = ("A".."Z").antipairs.map({ .key => .value + 1 });

	my @complete;
	my $time = 0;
	my sub do-work {
		my @working = @workers.pairs.grep({ .value<time> }).map({.key});
		if @working {
			for @working -> $i {
				@workers[$i]<time>--;
				if @workers[$i]<time> == 0 {
					my $step = @workers[$i]<step>;
					@complete.append($step);
					@workers[$i] = False;
				}
			}
			$time++;
			return True;
		}
		return False;
	}

	while %dep {
		do-work();

		for @workers.pairs.grep({ !.value }).map({.key}) -> $i {
			for %dep.keys.sort -> $step {
				if %dep{$step} (<=) @complete {
					my $time = $step-time + %time{$step};
					%dep{$step}:delete;
					@workers[$i] = {
						time => $time,
						step => $step,
					};
					last;
				}
			}
		}
	}
	Nil while do-work();
	return $time;
}

my @sample = q:to/EOL/.lines.&read-depends;
Step C must be finished before step A can begin.
Step C must be finished before step F can begin.
Step A must be finished before step B can begin.
Step A must be finished before step D can begin.
Step B must be finished before step E can begin.
Step D must be finished before step E can begin.
Step F must be finished before step E can begin.
EOL

#@sample.perl.say;
is dep-sort( @sample ).join, "CABDFE", "Found the expected sample order";
is job-queue( @sample ), 15, "Completed sample job";

my @input = '07-input'.IO.lines.&read-depends;
#@input.perl.say;
is dep-sort( @input ).join, "EPWCFXKISTZVJHDGNABLQYMORU", "Sorted input";
is job-queue( @input, 60, 5 ), 952, "Completed input job";

done-testing;
