use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP/CDN',
    VERSION_FROM      => 'lib/HTTP/CDN.pm', # finds $VERSION
    PREREQ_PM         => {
        'MIME::Types' => 1.28,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/CDN.pm', # retrieve abstract from module
       AUTHOR         => 'Martyn Smith <martyn@shoptime.co.nz>') : ()),
);
