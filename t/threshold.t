# Tests for the "threshold" comparison method

use warnings;
use strict;

use Image::Compare qw/compare/;
require "t/helper.pm";

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

$| = 1;
print "1..2\n";

# Test two images that are different, but not that different
my $img1 = make_image(
	[10, 20],
	[20, 10],
);
my $img2 = make_image(
	[15, 15],
	[15, 15],
);
# Max diff is 5, 5 * sqrt(3) == 8.66, which is less than 10, so this should
# return true indicating images are the same.
ok( compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::THRESHOLD,
	args   => 10,
), 1);

# Test two images that are more different
$img2 = make_image(
	[20, 10],
	[10, 20],
);
# Max diff is 10, 10 * sqrt(3) == 17.32, which is more than 10, so this should
# return false indicating images are different.
ok(!compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::THRESHOLD,
	args   => 10,
), 2);

