#!perl6

my %r = ('a'..'h').map({ $_ => 0 });

# %r<a> is "debug flag" set to 0 for debugging
# %r<a> = 1;						# debug off

%r<b> = 99;						#  0 set b 99
%r<c> = %r<b>;						#  1 set c b
if %r<a> != 0	# if not debug				#  2 jnz a 2
{							#  3 jnz 1 5
	%r<b> *= 100;					#  4 mul b 100
	%r<b> -= -100_000;				#  5 sub b -100000
	%r<c>  = %r<b>;					#  6 set c b
	%r<c> -= -17000; }				#  7 sub c -17000
repeat {%r<f> = 1;					#  8 set f 1
	%r<d> = 2;					#  9 set d 2
	repeat {%r<e> = 2;				# 10 set e 2
		repeat {%r<g>  = %r<d>;			# 11 set g d
			%r<g> *= %r<e>;			# 12 mul g e
			%r<g> -= %r<b>;			# 13 sub g b
			if not %r<g> {			# 14 jnz g 2
				%r<f> = 0; }		# 15 set f 0
			%r<e> -= -1;			# 16 sub e -1
			%r<g>  = %r<e>;			# 17 set g e
			%r<g> -= %r<b>;			# 18 sub g b
		} while %r<g> != 0;			# 19 jnz g -8
		%r<d> -= -1;				# 20 sub d -1
		%r<g>  = %r<d>;				# 21 set g d
		%r<g> -= %r<b>;				# 22 sub g b
	} while %r<g> != 0;				# 23 jnz g -13
	if not %r<f> {					# 24 jnz f 2
		%r<h> -= -1; }				# 25 sub h -1
	%r<g>  = %r<b>;					# 26 set g b
	%r<g> -= %r<c>;					# 27 sub g c
	if not %r<g> != 0 {				# 28 jnz g 2
		last if 1 != 0; }			# 29 jnz 1 3
	%r<b> -= -17;					# 30 sub b -17
} while 1 != 0;						# 31 jnz 1 -23
