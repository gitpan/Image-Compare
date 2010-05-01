use Test::Pod::Coverage tests=>7;
for my $module (qw/
	Image::Compare
	Image::Compare::Comparator
	Image::Compare::EXACT
	Image::Compare::THRESHOLD
	Image::Compare::AVG_THRESHOLD
	Image::Compare::IMAGE
	Image::Compare::THRESHOLD_COUNT
/) {
	pod_coverage_ok(
		$module,
		{ also_private => [qw/MEAN MEDIAN/] },
		"$module documentation coverage"
	);
}
