# Image::Compare, used to find if two images differ significantly from one
# another.

package Image::Compare;

require 5;
use strict;
use warnings;

use base qw/Exporter/;
use Imager;
use Imager::Color::Float;  # It is absurd that I have to do this.
use LWP;
use Regexp::Common qw/URI/;

our $VERSION = "0.2";
our @EXPORT_OK = qw/compare/;

use constant EXACT => 1;
use constant THRESHOLD => 2;
use constant IMAGE => 3;
use constant AVG_THRESHOLD => 4;

use constant MEAN => 1;
use constant MEDIAN => 2;

##   Public methods begin here

# The constructor method.
# Takes a hash of arguments:  (all are optional)
#   image1 => <Imager object or file name representing the first image>
#   image2 => <Imager object or file name representing the second image>
#   method => <Integer constant representing the comparison method>
# See the documentation on the relevant option setters for more details
sub new {
	my $proto = shift;
	my %args = @_;
	my $class = ref($proto) || $proto;  # Bite me, Randal.
	my $self = {};
	bless($self, $class);
	# These are default values
	if ($args{image1}) {
		$self->set_image1(
			img  => $args{image1},
			type => $args{type1}
		);
	}
	if ($args{image2}) {
		$self->set_image2(
			img  => $args{image2},
			type => $args{type2}
		);
	}
	if ($args{method}) {
		$self->set_method(
			method => $args{method},
			args => $args{args}
		);
	}
	return $self;
}

# The next two just use the input to fetch image data and store it as an
# Imager object.  Currently supported image types:
#   File handle
#   File name
#   Imager object
#   URL
sub set_image1 {
	my $self = shift;
	my %args = @_;
	$self->{_IMG1} = _get_image($args{img}, $args{type});
}

sub set_image2 {
	my $self = shift;
	my %args = @_;
	$self->{_IMG2} = _get_image($args{img}, $args{type});
}

# Given input as defined above, returns an Imager object representing the
# image.
sub _get_image {
	my($img, $type) = @_;
	unless ($img) {
		die "Missing 'img' parameter";
	}
	# This is the simplest case
	if (ref($img) eq 'Imager') {
		return $img;
	}
	my $errmsg = "Unable to read image data from ";
	my %args;
	$args{type} = $type;
	if (!ref($img)) {
		if ($RE{URI}->matches($img)) {
			$errmsg .= "URL '$img'";
			my $ua = LWP::UserAgent->new();
			$ua->agent("Image::Compare/v$VERSION ");
			my $res = $ua->request(HTTP::Request->new(GET => $img));
			$args{data} = $res->content();
			if (!$type) {
				$args{type} = $res->content_type();
				$args{type} =~ s!^image/!!;
			}
		}
		else {
			$errmsg .= "file '$img'";
			$args{file} = $img;
		}
	}
	else {
		die "Unrecognized input type: '" . ref($img) . "'";
	}
	my $new = Imager->new();
	$new->read(%args) || die($errmsg . ": '" . $new->{ERRSTR} . "'");
	return $new;
}

# This sets the comparison method and any arguments required, if any.
# The currently-supported methods, and their arguments, are:
#    EXACT:
#      Returns true if two images are exactly the same.
#      No arguments
#    THRESHOLD:
#      Returns true if no single-pixel difference in the images is greater
#      than a threshold value.
#      One required argument is the threshold value.
#    AVG_THRESHOLD:
#      Returns true if the average pixel difference of the two images is
#      lower than a given threshold value.
#      The required argument is a hash ref with the following required keys:
#          type => Must be one of the constants MEAN or MEDIAN
#          value => The threshold value
#    IMAGE:
#      Returns an Imager object for an image representing the pixel-by-pixel
#	     differences between the two images.  Returns undef on error.
#      There is one optional argument.  If it is provided and true then
#      the output will be in color, otherwise output will be grayscale.
#      Color output is on a red to green to blue gradient, so the most
#      change will be blue and the least, red.
sub set_method {
	my $self = shift;
	my %args = @_;
	if (!$args{method}) {
		die "Missing required argument 'method'";
	}
	if ($args{method} == &EXACT) {
		$self->{_CMP} = Image::Compare::_THRESHOLD->new(0);
	}
	elsif ($args{method} == &THRESHOLD) {
		$self->{_CMP} = Image::Compare::_THRESHOLD->new($args{args});
	}
	elsif ($args{method} == &AVG_THRESHOLD) {
		$self->{_CMP} = Image::Compare::_AVG_THRESHOLD->new($args{args});
	}
	elsif ($args{method} == &IMAGE) {
		$self->{_CMP} = Image::Compare::_IMAGE->new($args{args});
	}
	else {
		die "Unrecognized method: '$args{method}'";
	}
}

# Compares two images and returns a result.
sub compare {
	my $self;
	# This can be called as an instance method
	if (ref($_[0]) eq 'Image::Compare') {
		$self = shift;
	}
	else {
		# Or, as a class method, if you swing that way...
		if ($_[0] eq 'Image::Compare') {
			shift;
		}
		# Or just as a normal method, with the normal arguments to "new"
		$self = Image::Compare->new(@_);
	}
	# Sanity checking
	unless ($self->{_IMG1}) {
		die "Image 1 not specified";
	}
	unless ($self->{_IMG2}) {
		die "Image 2 not specified";
	}
	unless ($self->{_CMP}) {
		die "Comparison method not specified";
	}
	# If the images are different dimensions then we can be pretty sure they're
	# not the same.
	if (
		($self->{_IMG1}->getheight() != $self->{_IMG2}->getheight()) ||
		($self->{_IMG1}->getwidth()  != $self->{_IMG2}->getwidth() )
	) {
		return $self->{_CMP}->err();
	}
	# This comparator object needs some special data
	if (ref($self->{_CMP}) eq 'Image::Compare::_IMAGE') {
		$self->{_CMP}->setup_img_dimensions(
			$self->{_IMG1}->getwidth(),
			$self->{_IMG1}->getheight(),
		);
	}
	# Do the comparison
	for my $i (0 .. ($self->{_IMG1}->getwidth() - 1)) {
		for my $j (0 .. ($self->{_IMG1}->getheight() - 1)) {
			my @pix1 = $self->{_IMG1}->getpixel(x => $i, y => $j)->rgba();
			my @pix2 = $self->{_IMG2}->getpixel(x => $i, y => $j)->rgba();
			my $diff = sqrt(
				( ($pix1[0] - $pix2[0]) ** 2 ) +
				( ($pix1[1] - $pix2[1]) ** 2 ) +
				( ($pix1[2] - $pix2[2]) ** 2 )
			);
			my $res = $self->{_CMP}->accumulate($diff, $i, $j);
			if (defined($res)) {
				return $res;
			}
		}
	}
	return $self->{_CMP}->result();
}

package Image::Compare::_Comparator;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{args} = shift;
	bless($self, $class);
	return $self;
}

sub err {
	return undef;
}

package Image::Compare::_THRESHOLD;

our @ISA = qw/Image::Compare::_Comparator/;

sub accumulate {
	my $self = shift;
	my $diff = shift;
	if ($diff > $self->{args}) {
		return 0;
	}
	return undef;
}

sub result { return 1; }

package Image::Compare::_AVG_THRESHOLD;

our @ISA = qw/Image::Compare::_Comparator/;

sub accumulate {
	my $self = shift;
	if ($self->{args}{type} == &Image::Compare::MEAN) {
		$self->{count}++;
		$self->{sum} += shift();
	}
	elsif ($self->{args}{type} == &Image::Compare::MEDIAN) {
		push(@{$self->{scores}}, shift());
	}
	else {
		die "Unrecognized average type: '$self->{args}{type}'";
	}
	return undef;
}

sub result {
	my $self = shift;
	my $val = 0;
	if ($self->{args}{type} == &Image::Compare::MEAN) {
		$val = $self->{sum} / $self->{count};
	}
	elsif ($self->{args}{type} == &Image::Compare::MEDIAN) {
		my @vals = sort @{$self->{scores}};
		if (@vals % 2) {
			# Return the middle value
			$val = $vals[(@vals / 2)];
		}
		else {
			# Return the mean of the middle two values
			$val  = $vals[ @vals / 2     ];
			$val += $vals[(@vals / 2) - 1];
			$val /= 2;
		}
	}
	return $val <= $self->{args}{value};
}

package Image::Compare::_IMAGE;

our @ISA = qw/Image::Compare::_Comparator/;

sub setup_img_dimensions {
	my $self = shift;
	$self->{count} = 0;
	$self->{img} = Imager->new(
		xsize => $_[0],
		ysize => $_[1],
	);
}

sub accumulate {
	my $self = shift;
	my($diff, $x, $y) = @_;
	my $color;
	if ($self->{args}) {
		# Color output
		# TODO: Model this color ramp as an Imager::Fountain, and get the color
		# from that.
		# TODO: Let users pass in their own fountains.
		$color = [0, 0, 0];
		if ($diff < 221) {
			$color->[0] = round(255 - (255 * $diff / 221));
			$color->[1] = round(255 * $diff / 221);
		}
		elsif ($diff == 221) {
			$color->[1] = 255;
		}
		else {
			$color->[1] = round(255 - (255 * ($diff - 221) / 221));
			$color->[2] = round(255 * ($diff - 221) / 221);
		}
	}
	else {
		# Grayscale output
		$color = [(round($diff * 255 / 441.7)) x 3];
	}
	$self->{img}->setpixel(
		x     => $x,
		y     => $y,
		color => $color,
	);
	$self->{count}++;
	return undef;
}

sub result {
	my $self = shift;
	return $self->{img};
}

sub round {
	my $in = shift;
	$in =~ s/\.(\d)\d*//;
	if ($1 && ($1 > 5)) {
		$in++;
	}
	return $in;
}

1;

__END__

=head1 NAME

Image::Compare - Compare two images in a variety of ways.

=head1 USAGE

 use Image::Compare;
 use warnings;
 use strict;

 my($cmp) = Image::Compare->new();
 $cmp->set_image1(
     img  => '/path/to/some/file.jpg',
     type => 'jpg',
 );
 $cmp->set_image2(
     img  => 'http://somesite.com/someimage.gif',
 );
 $cmp->set_method(
     method => &Image::Compare::THRESHOLD,
     args   => 25,
 );
 if ($cmp->compare()) {
     # The images are the same, within the threshold
 }
 else {
     # The images differ beyond the threshold
 }

=head1 OVERVIEW

This library implements a system by which 2 image files can be compared,
using a variety of comparison methods.  In general, those methods operate
on the images on a pixel-by-pixel basis and reporting statistics or data
based on color value comparisons.

C<Image::Compare> makes heavy use of the C<Imager> module, although it's not
neccessary to know anything about it in order to make use of the compare
functions.  However, C<Imager> must be installed in order to use this
module, and file import types will be limited to those supported by your
installed C<Imager> library.

In general, to do a comparison, you need to provide 3 pieces of information:
the first image to compare, the second image to compare, and a comparison
method.  Some comparison methods also require extra arguments -- in some cases
a boolean value, some a number and some require a hash reference with
structured data.  See the documentation below for information on how to use
each comparison method.

C<Image::Compare> provides 3 different ways to invoke its comparison
functionality -- you can construct an C<Image::Compare> object and call
C<set_*> methods on it to give it the information, then call C<compare()> on
that object, or you can construct the Image::Compare with all of the
appropriate data right off the bat, or you can simply call C<compare()>
with all of the information.  In this third case, you can call C<compare()>
as a class method, or you can simply invoke the method directly from the
C<Image::Compare> namespace.  If you'd like, you can also pass the word
C<compare> to the module when you C<use> it and the method will be
imported to your local namespace.

=head1 COMPARISON METHODS

=over 4

=item EXACT

The EXACT method simply returns true if every single pixel of one image
is exactly the same as every corresponding pixel in the other image, or false
otherwise.  It takes no arguments.

 $cmp->set_method(
     method => &Image::Compare::EXACT,
 );

=item THRESHOLD


The THRESHOLD method returns true if no pixel difference between the two images
exceeds a certain threshold, and false if even one does.  Note that differences
are measured in a sum of squares fashion (vector distance), so the maximum
difference is C<255 * sqrt(3)>, or roughly 441.7.  Its argument is the
difference threshold.  (Note:  EXACT is the same as THRESHOLD with an
argument of 0.)

 $cmp->set_method(
     method => &Image::Compare::THRESHOLD,
     args   => 50,
 );

=item AVG_THRESHOLD

The AVG_THRESHOLD method returns true if the average difference over all pixel
pairings between the two images is under a given threshold value.  Two
different average types are available: MEDIAN and MEAN.  Its argument is a
hash reference, contains keys "type", indicating the average type, and
"value", indicating the threshold value.

 $cmp->set_method(
     method => &Image::Compare::AVG_THRESHOLD,
     args   => {
         type  => &Image::Compare::MEAN,
         value => 35,
     },
 );

=item IMAGE

The IMAGE method returns an C<Imager> object of the same dimensions as your
input images, with each pixel colored to represent the pixel color difference
between the corresponding pixels in the input.

Its only argument is a boolean.  If the argument is omitted or false, then
the output image will be grayscale, with black meaning no change and white
meaning maximum change.  If the argument is a true value, then the output
will be in color, ramping from pure red at 0 change to pure green at 50% of
maximum change, and then to pure blue at maximum change.

 $cmp->set_method(
     method => &Image::Compare::IMG,
     args   => 1,   # Output in color
 );

=back

=head1 METHODS

=over 4


=item new()

=item new(image1 => { .. }, image2 => { .. }, method => { .. })

This is the constructor method for the class.  You may optionally pass it
any of 3 arguments, each of which takes a hash reference as data, which
corresponds exactly to the semantics of the C<set_*> methods, as described
below.

=item $cmp->set_image1(img => $data, type => $type)
=item $cmp->set_image2(img => $data, type => $type)

Sets the data for the appropriate image based on the input parameters.
The C<img> parameter can either be an C<Imager> object, a file path or a URL.
If a URL, it must be of a scheme supported by your C<LWP> install.  The C<type>
argument is optional, and will be used to override the image type deduced
from the input.  Again, the image type used must be one supported by your
C<Imager> install, and its format is determined entirely by C<Imager>.  See
the documentation on C<Imager::Files> for a list of image types.

=item $cmp->set_method(method => $method, args => $args)

Sets the comparison method for the object.  See the section above for details
on different comparison methods.

=item $cmp->compare()

=item compare(image1 => { .. }, image2 => { .. }, method => { .. })

Actually does the comparison.  The return value is determined by the comparison
method described in the previous section, so look there to see the details.
As described above, this can be called as an instance method, in which case
the values set at construction time or through the C<set_*> methods will be
used, or it can be called as a class method or as a simple subroutine.

In the latter case, all of the information must be provided as arguments to
the function call.  Those argument have exactly the same semantics as the
arguments for C<new()>, so see that section for details.

=back

=head1 Future Work

=over 4

=item *

I would like to implement more comparison methods.  I will have to use the
module myself somewhat before I know which ones would be useful to add, so
I'm releasing this initial version now with a limited set of comparisons.

I also more than welcome suggestions from users as to comparison methods
they would find useful, so please let me know if there's anything you'd like to
see the module be able to do.  This module is meant more to be a framework
for image comparison and a collection of systems working within that
framework, so the process of adding new comparison methods is reasonably
simple and painless.

=item *

I bet the input processing could be more bulletproof.  I am pretty certain of
it, in fact.

=item *

I should probably make accessor methods for the 3 mutators that already exist.
I couldn't think of a good reason for it though, and I'm lazy.  If enough (1)
people request it though, I'll put it in.

=item *

I'd like to make it so users can define their own color functions to be used
in creating the output for the IMAGE comparison method.  I will probably do
this using Imager::Color::Fountain objects, but that is kind of tricky, so
I'm leaving it out for now.

=item *

I don't think I'm doing the whole required modules thing correctly, and I
should probably make it so that it can operate without LWP or Regexp::Common.

=back

=head1 Known Issues

=over 4

=item *

None at this time.

=back

=head1 AUTHOR

Copyright 2006 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
