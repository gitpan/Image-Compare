# Tests for the "exact" comparison method

use warnings;
use strict;

use Image::Compare;
require "t/helper.pm";

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

$| = 1;
print "1..2\n";

# Test two images that are the same
my $img1 = make_image(
	[10, 20],
	[20, 10],
);
my $img2 = make_image(
	[10, 20],
	[20, 10],
);
my $cmp = Image::Compare->new(
	image1 => $img1,
	image2 => $img2,
	method => &Image::Compare::EXACT,
);
ok( $cmp->compare(), 1);

# Test two images that are NOT the same
$img2 = make_image(
	[20, 10],
	[10, 20],
);
$cmp = Image::Compare->new(
	image1 => $img1,
	image2 => $img2,
	method => &Image::Compare::EXACT,
);
ok(!$cmp->compare(), 2);

