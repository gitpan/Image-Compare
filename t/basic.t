# Tests for basic functionality of the class

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use Image::Compare;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

# Test adding an image as an Imager object using set_image1
my $cmp = Image::Compare->new();
$cmp->set_image1(img => Imager->new(xsize => 50, ysize => 50));
ok( (ref($cmp->{_IMG1}) eq 'Imager'), 2);

# Test adding an image as a URL using set_image1
$cmp = Image::Compare->new();
$cmp->set_image1(
	img => 'http://mirrors.cpan.org/img/cpanlog.jpg',
);
ok( (ref($cmp->{_IMG1}) eq 'Imager'), 3);
ok( ($cmp->{_IMG1}->getwidth() == 88), 4);

# Test adding an image as a file path using set_image1
$cmp = Image::Compare->new();
$cmp->set_image1(img => 't/sample.png');
ok( (ref($cmp->{_IMG1}) eq 'Imager'), 5);
ok( ($cmp->{_IMG1}->getwidth() == 48), 6);

# Now let's test get_image2.  This test need only verify the basic
# functionality and not be as exhaustive as those before.
$cmp->set_image2(img => 't/sample.png');
ok( (ref($cmp->{_IMG2}) eq 'Imager'), 7);
ok( ($cmp->{_IMG2}->getwidth() == 48), 8);

# Test out set_method
$cmp->set_method(
	method => &Image::Compare::THRESHOLD,
	args => 4
);
ok( (ref($cmp->{_CMP}) eq 'Image::Compare::_THRESHOLD'), 9);
ok( ($cmp->{_CMP}->{args} == 4), 10);

# Finally, let's make sure that calling new() with a bunch of arguments
# works the way it ought.
$cmp = Image::Compare->new(
	image1 => Imager->new(
		xsize => 51,
		ysize => 51,
	),
	image2 => Imager->new(
		xsize => 52,
		ysize => 52,
	),
	method => &Image::Compare::AVG_THRESHOLD,
	args   => {
		type  => &Image::Compare::MEDIAN,
		value => 3.5,
	},
);

ok( (ref($cmp->{_IMG1}) eq 'Imager'),   11);
ok( ($cmp->{_IMG1}->getwidth()  == 51), 12);
ok( ($cmp->{_IMG1}->getheight() == 51), 13);

ok( (ref($cmp->{_IMG2}) eq 'Imager'),   14);
ok( ($cmp->{_IMG2}->getwidth()  == 52), 15);
ok( ($cmp->{_IMG2}->getheight() == 52), 16);

ok( (ref($cmp->{_CMP}) eq 'Image::Compare::_AVG_THRESHOLD'), 17);
ok( (ref($cmp->{_CMP}{args}) eq 'HASH'), 18);
ok( ($cmp->{_CMP}{args}{type}  == &Image::Compare::MEDIAN), 19);
ok( ($cmp->{_CMP}{args}{value} == 3.5), 20);
