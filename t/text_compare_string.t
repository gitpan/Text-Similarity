# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/text_compare_string.t'
# Note that because of the file paths used this must be run from the 
# directory in which /t resides 
#
# Last modified by : '$Id: text_compare_string.t,v 1.4 2008/04/04 18:55:22 tpederse Exp $'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

# set up file access in an OS neutral way
use File::Spec;

$text_compare_pl = File::Spec->catfile ('bin','text_compare.pl');
ok (-e $text_compare_pl);

$stoplist_txt = File::Spec->catfile ('bin','stoplist.txt');
ok (-e $stoplist_txt);

# use this to find Text::Similarity::Overlaps module

$inc = "-Iblib/lib";

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string 'cat' 'cat' `; 
chomp $output;

is ($output, 1, "exact match");

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string 'CAT' 'cat' `; 
chomp $output;

is ($output, 1, "case insensitive match");

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string '.....CAT' 'cat .............' `; 
chomp $output;

is ($output, 1, "case insensitive and ignore punctuation match");

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string '' 'cat .............' `; 
chomp $output;

is ($output, 0, "match with empty");

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string '' '' `; 
chomp $output;

is ($output, 0, "match with empties");

# ---------------------------------------------------------------------

$output = `$^X $inc $text_compare_pl --type Text::Similarity::Overlaps --string 'sir winston churchill' 'winston churchill SIR!!!' `; 
chomp $output;

is ($output, 1, "order doesn't affect score");

# ---------------------------------------------------------------------



