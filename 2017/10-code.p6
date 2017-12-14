#!perl6
use Test;

use lib IO::Path.new($?FILE).parent.add('lib');
use Knot;
use KnottedString;

# Here's an example using a smaller list:
{
# Suppose we instead only had a circular list containing five elements, 0, 1,
# 2, 3, 4, and were given input lengths of 3, 4, 1, 5.
    my $string = Knot.new(:string(0...4));

#     The list begins as [0] 1 2 3 4 (where square brackets indicate the
#     current position).  The first length, 3, selects ([0] 1 2) 3 4 (where
#     parentheses indicate the sublist to be reversed).  After reversing that
#     section (0 1 2 into 2 1 0), we get ([2] 1 0) 3 4.  Then, the current
#     position moves forward by the length, 3, plus the skip size, 0: 2 1 0 [3]
#     4. Finally, the skip size increases to 1.
    $string.tie(3);
    is $string.Str, "2 1 0 3 4", "String is as expected after first knot";
    is $string.gist, "3 4 2 1 0: [3]",
        "State is correct after first knot";

#     The second length, 4, selects a section which wraps: 2 1) 0 ([3] 4.  The
#     sublist 3 4 2 1 is reversed to form 1 2 4 3: 4 3) 0 ([1] 2.  The current
#     position moves forward by the length plus the skip size, a total of 5,
#     causing it not to move because it wraps around: 4 3 0 [1] 2. The skip
#     size increases to 2.
    $string.tie(4);
    is $string.Str, "4 3 0 1 2", "String is as expected after second knot";
    is $string.gist, "1 2 4 3 0: [3 4]",
        "State is correct after second knot";

#     The third length, 1, selects a sublist of a single element, and so
#     reversing it has no effect.  The current position moves forward by the
#     length (1) plus the skip size (2): 4 [3] 0 1 2. The skip size increases
#     to 3.
    $string.tie(1);
    is $string.Str, "4 3 0 1 2", "String is as expected after third knot";
    is $string.gist, "3 0 1 2 4: [3 4 1]",
        "State is correct after third knot";

#     The fourth length, 5, selects every element starting with the second: 4)
#     ([3] 0 1 2. Reversing this sublist (3 0 1 2 4 into 4 2 1 0 3) produces:
#     3) ([4] 2 1 0.  Finally, the current position moves forward by 8: 3 4 2 1
#     [0]. The skip size increases to 4.
    $string.tie(5);
    is $string.Str, "3 4 2 1 0", "String is as expected after fourth knot";
    is $string.gist, "0 3 4 2 1: [3 4 1 5]",
        "State is correct after fourth knot";

# In this example, the first two numbers in the list end up being 3 and 4; to
# check the process, you can multiply them together to produce 12.
    is $string.value[0..1].reduce(&[*]),
        12, "Product of first two digits is 12";
}
# However, you should instead use the standard list size of 256 (with values 0
# to 255) and the sequence of lengths in your puzzle input. Once this process
# is complete, what is the result of multiplying the first two numbers in the
# list?

{
    my $string = Knot.new;
    $string.tie($_) for "10-input".IO.lines.first.split(',').map(*.Int);
    is $string.value[0..1].reduce(&[*]), 23715, "String has value 23715";
}

# --- Part Two ---
{
# Here are some example hashes:
    is KnottedString.new('').hashed, 'a2582a3a0e66e6e86e3812dcb672a272',
        "The empty string becomes a2582a3a0e66e6e86e3812dcb672a272.";
    is KnottedString.new('AoC 2017').hashed, '33efeb34ea91902bb2f59c9920caa6cd',
       "AoC 2017 becomes 33efeb34ea91902bb2f59c9920caa6cd.";
    is KnottedString.new('1,2,3').hashed, '3efbe78a8d82f29979031a4aa0b16a9d',
       "1,2,3 becomes 3efbe78a8d82f29979031a4aa0b16a9d.";
    is KnottedString.new('1,2,4').hashed, '63960835bcdc130f0b66d7ff4f6a5a8e',
        "1,2,4 becomes 63960835bcdc130f0b66d7ff4f6a5a8e.";
}

# Treating your puzzle input as a string of ASCII characters, what is the Knot
# Hash of your puzzle input? Ignore any leading or trailing whitespace you
# might encounter.

is KnottedString.new("10-input".IO.lines.head).hashed,
    '541dc3180fd4b72881e39cf925a50253',
    "Input hashed as expected";

done-testing;
