# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Similarity.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

BEGIN {use_ok Text::Similarity::Overlaps}

my %opt_hash = (Text::Similarity::NORMALIZE => 1);
my $overlapmod = Text::Similarity::Overlaps->new (\%opt_hash);

ok ($overlapmod);
my $score = $overlapmod->getSimilarity ('GPL.txt', 'GPL.txt');
is ($score, 1, "self similarity of GPL");

my $tempfile1 = "tempfile$$.temp1";
my $tempfile2 = "tempfile$$.temp2";

ok (open (FH1, '>', $tempfile1));
print FH1 "This is a test\n";
close FH1;

ok (open (FH2, '>', $tempfile2));
print FH2 "This is also a test\n";
close FH2;

$score = $overlapmod->getSimilarity ($tempfile1, $tempfile2);

cmp_ok ($score, '<', 1);
cmp_ok ($score, '>', 0);

END {ok (unlink ($tempfile1, $tempfile2))}
