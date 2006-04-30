# Tests for the "avg_threshold" comparison method

use warnings;
use strict;

use Image::Compare qw/compare/;
require "t/helper.pm";

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

$| = 1;
print "1..4\n";

# Test "mean" average type with true result
my $img1 = make_image(
	[10, 20],
	[20, 10],
);
my $img2 = make_image(
	[11, 21],
	[15, 12],
);
# Total diff is 1 + 1 + 5 + 2 = 9.  9 * sqrt(3) = 15.6, divide that by 4 and you
# get 3.9. So if we set our threshold to 4, we should get a true result.
ok( compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::MEAN,
		value => 4,
	},
), 1);

# Test "mean" average type with true result
# If we set the threshold to 3.7, then we should get a false result.
ok(!compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::MEAN,
		value => 3.7,
	},
), 2);

# Test "median" average with true result
# Diffs are 1, 1, 5 and 2.  Middle two values are 1 and 2, so the median 
# will be 1.5.  1.5 * sqrt(3) is 2.6, so if we set the value to 3, we should
# get a true value.
ok( compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::MEDIAN,
		value => 3,
	},
), 3);

# And if we set it to 2.3, we should get false
ok(!compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::MEDIAN,
		value => 2.3,
	},
), 4);
