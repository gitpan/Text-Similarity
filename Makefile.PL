use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @programs = qw(text_compare.pl);

WriteMakefile(
    NAME              => 'Text::Similarity',
    VERSION_FROM      => 'lib/Text/Similarity.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => [map "bin/$_", @programs],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Similarity.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Michelizzi <mich0212 at d.umn.edu>') : ()),
);
