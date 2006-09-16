use inc::Module::Install;
    
name     'Image-Compare';
all_from 'Compare.pm';
author   'Avi Finkel';
license  'perl';

requires 'Imager' => 0;
requires 'LWP' => 0;
requires 'Regexp::Common' => 0;
				    
auto_install;
WriteAll;
