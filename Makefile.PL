use inc::Module::Install;
    
name     'Image-Compare';
all_from 'lib/Image/Compare.pm';
author   'Avi Finkel';
license  'perl';

requires 'Imager' => 0.54;

recommends 'LWP';

build_requires 'Test::Pod' => 1.26;
build_requires 'Test::Pod::Coverage' => 1.08;
build_requires 'Pod::Coverage' => 0.18;
				    
auto_install;
WriteAll;
