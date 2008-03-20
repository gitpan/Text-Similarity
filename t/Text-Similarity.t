# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Similarity.t'
# Last modified by : $Id: Text-Similarity.t,v 1.7 2008/03/20 03:05:47 tpederse Exp $
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;

BEGIN {use_ok Text::Similarity}
BEGIN {use_ok Text::Similarity::Overlaps}

my %opt_hash = (Text::Similarity::NORMALIZE => 1);
my $overlapmod = Text::Similarity::Overlaps->new (\%opt_hash);
ok ($overlapmod);

# create test files in such a way that their absolute location doesn't
# need to be known, and is hopefully portable across various os platforms

my $tempfile0 = "tempfile$$.temp0";
my $tempfile1 = "tempfile$$.temp1";
my $tempfile2 = "tempfile$$.temp2";
my $tempfile3 = "tempfile$$.temp3";
my $tempfile4 = "tempfile$$.temp4";

ok (open (FH0, '>', $tempfile0));
print FH0 "   \n";
close FH0;

ok (open (FH1, '>', $tempfile1));
print FH1 "aaa bbb ccc ddd eee fff ggg hhh\n";
close FH1;

ok (open (FH2, '>', $tempfile2));
print FH2 "aaa ccc eee ggg\n";
close FH2;


ok (open (FH3, '>', $tempfile3));
print FH3 "aaa               ccc                 eee     \n ggg\n";
close FH3;

ok (open (FH4, '>', $tempfile4));
print FH4 "this file has actual words, unlike the files with aaa bbbn";
close FH4;

# exact matching between two identical files
$score = $overlapmod->getSimilarity ($tempfile1, $tempfile1);
is ($score, 1, "self similarity of tempfile1");

$score = $overlapmod->getSimilarity ($tempfile2,$tempfile2);
is ($score, 1, "self similarity of tempfile2");

# self similarity of an empty file? call it 0 since nothing matches

$score = $overlapmod->getSimilarity ($tempfile0, $tempfile0);
is ($score, 0, "self similarity of tempfile0");

# exact matching between two files that only differ with white space

$score = $overlapmod->getSimilarity ($tempfile2, $tempfile3);
is ($score, 1, "similarity of tempfile2 and tempfile3");

# no match to an empty file (text0.txt)
# caused divide by zero error in 0.02

$score = $overlapmod->getSimilarity ($tempfile2, $tempfile0);
is ($score, 0, "similarity of tempfile2 and tempfile0");

$score = $overlapmod->getSimilarity ($tempfile0, $tempfile1);
is ($score, 0, "similarity of tempfile0 and tempfile1");

# partial match, above .5 score

$score = $overlapmod->getSimilarity ($tempfile1, $tempfile2);
cmp_ok ($score, '<', 1);
cmp_ok ($score, '>', .5);

# incidental match, small nonzero score

$score = $overlapmod->getSimilarity ($tempfile1, $tempfile4);
cmp_ok ($score, '<', .5);
cmp_ok ($score, '>', 0);

END {ok (unlink ($tempfile0, $tempfile1, $tempfile2, $tempfile3, $tempfile4))}
