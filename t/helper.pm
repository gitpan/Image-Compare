# Helper methods for making images etc

use warnings;
use strict;

sub make_image {
	my $img = Imager->new(
		xsize => scalar(@_),
		ysize => scalar(@{$_[0]}),
	);
	for my $x (0 .. $#_) {
		for my $y (0 .. $#{$_[0]}) {
			$img->setpixel(x => $x, y => $y, color => [($_[$x][$y]) x 3]);
		}
	}
	return $img;
}

1;
