# Tests for the "image" comparison method

use warnings;
use strict;

use Image::Compare qw/compare/;
require "t/helper.pm";

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

$| = 1;
print "1..26\n";

# This is real simple -- just make sure that the image we get back is
# the right shape and has the right color values for the pixels
# First, let's do grayscale.
my $img1 = make_image(
	[10, 10],
	[10, 10],
);
my $img2 = make_image(
	[240, 3],
	[10, 92],
);
my $ret = compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::IMAGE,
);

ok( (ref($ret) eq 'Imager'), 1);
my @c = $ret->getpixel(x => 0, y => 0)->rgba();
# The first pixel has a color difference of 230.  This is grayscale so all
# color values should be equal.
ok( ($c[0] == 230), 2);
ok( ($c[1] == 230), 3);
ok( ($c[2] == 230), 4);

@c = $ret->getpixel(x => 0, y => 1)->rgba();
ok( ($c[0] == 7), 5);
ok( ($c[1] == 7), 6);
ok( ($c[2] == 7), 7);

@c = $ret->getpixel(x => 1, y => 0)->rgba();
ok( ($c[0] == 0), 8);
ok( ($c[1] == 0), 9);
ok( ($c[2] == 0), 10);

@c = $ret->getpixel(x => 1, y => 1)->rgba();
ok( ($c[0] == 82), 11);
ok( ($c[1] == 82), 12);
ok( ($c[2] == 82), 13);

# Now we test the color output mode
$ret = compare(
	image1 => $img1, image2 => $img2,
	method => &Image::Compare::IMAGE,
	args   => 1,
);

ok( (ref($ret) eq 'Imager'), 14);
# In color mode, differences are mapped to triplets of red / green / blue.
# If the difference is between 0 and 127, the color ramp is linear from red
# to green -- if it between 128 and 255, the ramp is from green to blue.  I
# will omit the detailed math here.
@c = $ret->getpixel(x => 0, y => 0)->rgba();
ok( ($c[0] ==   0), 15);
ok( ($c[1] ==  50), 16);
ok( ($c[2] == 205), 17);

@c = $ret->getpixel(x => 0, y => 1)->rgba();
ok( ($c[0] == 241), 18);
ok( ($c[1] ==  14), 19);
ok( ($c[2] ==   0), 20);

@c = $ret->getpixel(x => 1, y => 0)->rgba();
ok( ($c[0] == 255), 21);
ok( ($c[1] ==   0), 22);
ok( ($c[2] ==   0), 23);

@c = $ret->getpixel(x => 1, y => 1)->rgba();
ok( ($c[0] ==  91), 24);
ok( ($c[1] == 164), 25);
ok( ($c[2] ==   0), 26);
