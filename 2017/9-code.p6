#!perl6
use Test;

# --- Day 9: Stream Processing ---
#
# A large stream blocks your path. According to the locals, it's not safe to
# cross the stream at the moment because it's full of garbage. You look down at
# the stream; rather than water, you discover that it's a stream of characters.
#
# You sit for a while and record part of the stream (your puzzle input). The
# characters represent groups - sequences that begin with { and end with }.
# Within a group, there are zero or more other things, separated by commas:
# either another group or garbage. Since groups can contain other groups, a }
# only closes the most-recently-opened unclosed group - that is, they are
# nestable. Your puzzle input represents a single, large group which itself
# contains many smaller ones.
#
# Sometimes, instead of a group, you will find garbage. Garbage begins with <
# and ends with >. Between those angle brackets, almost any character can
# appear, including { and }. Within garbage, < has no special meaning.
#
# In a futile attempt to clean up the garbage, some program has canceled some
# of the characters within it using !: inside garbage, any character that comes
# after ! should be ignored, including <, >, and even another !.
#
# You don't see any characters that deviate from these rules. Outside garbage,
# you only find well-formed groups, and garbage always terminates according to
# the rules above.

# Here are some self-contained pieces of garbage:
#
#     <>, empty garbage.
#     <random characters>, garbage containing random characters.
#     <<<<>, because the extra < are ignored.
#     <{!>}>, because the first > is canceled.
#     <!!>, because the second ! is canceled, allowing the > to terminate the garbage.
#     <!!!>>, because the second ! and the first > are canceled.
#     <{o"i!a,<{i<a>, which ends at the first >.
#
# Here are some examples of whole streams and the number of groups they contain:
#
#     {}, 1 group.
#     {{{}}}, 3 groups.
#     {{},{}}, also 3 groups.
#     {{{},{},{{}}}}, 6 groups.
#     {<{},{},{{}}>}, 1 group (which itself contains garbage).
#     {<a>,<a>,<a>,<a>}, 1 group.
#     {{<a>},{<a>},{<a>},{<a>}}, 5 groups.
#     {{<!>},{<!>},{<!>},{<a>}}, 2 groups (since all but the last > are canceled).
#
# Your goal is to find the total count for all groups in your input. Each group
# is assigned a count which is one more than the count of the group that
# immediately contains it. (The outermost group gets a count of 1.)

grammar Garbage {
    token TOP     { :my $*COUNT = 0; <content> }

    method group {
        $*COUNT++;
        self.make($*COUNT.clone);
        LEAVE $*COUNT--;
        self.group_wrapped;
    }

    rule group_wrapped { '{' <content>* '}' }

    token piece_of_trash { <-[>]> }
    rule garbage_bag   { '<' <garbage>* '>' }
    token garbage      { \!. | <piece_of_trash> }
    rule content       { [ <group> | <garbage_bag> ] [ ',' <content> ]? }
}

ok Garbage.parse('a', :rule('garbage')), "'a' is garbage";
ok Garbage.parse('!a', :rule('garbage')), "'!a' is garbage";
ok Garbage.parse('!>', :rule('garbage')), "'!>' is garbage";
ok !Garbage.parse('>', :rule('garbage')), "'>' is not garbage";

ok !Garbage.parse('<>', :rule('garbage')), "'<>' is not garbage";
ok Garbage.parse('<>', :rule('garbage_bag')), "'<>' is a garbage_bag";

ok !Garbage.parse('<a>', :rule('garbage')), "'<a>' is not garbage";
ok Garbage.parse('<a>', :rule('garbage_bag')), "'<a>' is a garbage_bag";

ok !Garbage.parse('<!a>', :rule('garbage')), "'<!a>' not is garbage";
ok Garbage.parse('<!a>', :rule('garbage_bag')), "'<!a>' is a garbage_bag";

ok !Garbage.parse('<!>>', :rule('garbage')), "'<!>>' is not garbage";
ok Garbage.parse('<!>>', :rule('garbage_bag')), "'<!>>' is a garbage_bag";

ok Garbage.parse('<>,<a>,<!a>,<!>>', :rule('content')),
    "'<>,<a>,<!a>,<!>>' is content";

{
    my $*COUNT = 0;
    ok Garbage.parse('{<!>>}', :rule('content')), '"{<!>>}" is content';
    ok Garbage.parse('{<!>>}', :rule('group')), '"{<!>>}" is a group';
    ok Garbage.parse('{<>,<a>,<!a>,<!>>}', :rule('group')),
        '"{<>,<a>,<!a>,<!>>}" is a group';

    ok Garbage.parse('{<ab>}', :rule('content')), '"{<ab>}" is content';

    ok Garbage.parse('{<ab>},{<ab>}', :rule('content')),
        '"{<ab>},{<ab>}" is content';
    ok Garbage.parse('{<ab>},{<ab>},{<ab>},{<ab>}', :rule('content')),
        '"{<ab>},{<ab>},{<ab>},{<ab>}" is content';

    ok Garbage.parse('{{<ab>},{<ab>},{<ab>},{<ab>}}', :rule('content')),
        '"{{<ab>},{<ab>},{<ab>},{<ab>}}" is content';
    ok Garbage.parse('{{<ab>},{<ab>},{<ab>},{<ab>}}', :rule('group')),
        '"{{<ab>},{<ab>},{<ab>},{<ab>}}" is a group';
}

sub count-garbage(Str $stream, Str $want = 'score') {
    my $trash = 0;
    my &deep = sub (Match $m) {
        my @c;
        @c.push($m.made) if $m.made;
        for $m.hash.kv -> $k, $_ {
            $trash++ if $k eq 'piece_of_trash';
            if (.isa(Match)) {
                @c.push( |deep($_) );
            }
            elsif (.isa(Array)) {
                @c.push( |$_.map(&deep).flat );
            }
        }
        return @c;
    };
    my @c = deep( Garbage.parse($stream) );
    return $trash if $want eq 'trash';
    return @c;
}

is count-garbage('{}'),      <1>, "count of 1.";
is count-garbage('{{{}}}'),  <1 2 3>, "count of 1 + 2 + 3 = 6.";
is count-garbage('{{},{}}'), <1 2 2>, "count of 1 + 2 + 2 = 5.";
is count-garbage('{{{},{},{{}}}}'), <1 2 3 3 3 4>,
    'count of 1 + 2 + 3 + 3 + 3 + 4 = 16.';
is count-garbage('{<a>,<a>,<a>,<a>}'), <1>, "count of 1.";
is count-garbage('{{<ab>},{<ab>},{<ab>},{<ab>}}'), <1 2 2 2 2>,
    "count of 1 + 2 + 2 + 2 + 2 = 9.";
is count-garbage('{{<!!>},{<!!>},{<!!>},{<!!>}}'), <1 2 2 2 2>,
    "count of 1 + 2 + 2 + 2 + 2 = 9.";
is count-garbage('{{<a!>},{<a!>},{<a!>},{<ab>}}'), <1 2>,
    "count of 1 + 2 = 3.";

# What is the total count for all groups in your input?

is count-garbage("9-input".IO.lines.first).sum, 7616,
    "Total garbage in input is 7616";

# --- Part Two ---
#
# Now, you're ready to remove the garbage.
#
# To prove you've removed it, you need to count all of the characters within
# the garbage. The leading and trailing < and > don't count, nor do any
# canceled characters or the ! doing the canceling.

is count-garbage('<>', 'trash'), 0, "0 characters.";
is count-garbage('<random characters>', 'trash'), 17, "17 characters.";
is count-garbage('<<<<>', 'trash'), 3, "3 characters.";
is count-garbage('<{!>}>', 'trash'), 2, "2 characters.";
is count-garbage('<!!>', 'trash'), 0, "0 characters.";
is count-garbage('<!!!>>', 'trash'), 0, "0 characters.";
is count-garbage('<{o"i!a,<{i<a>', 'trash'), 10, "10 characters.";

# How many non-canceled characters are within the garbage in your puzzle input?

is count-garbage("9-input".IO.lines.first, 'trash'), 3838,
    "Total trash in input is 3838";

done-testing;
