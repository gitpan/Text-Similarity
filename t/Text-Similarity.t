# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Similarity.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN {use_ok Text::Similarity}
BEGIN {use_ok Text::Similarity::Overlaps}

my %opt_hash = (Text::Similarity::NORMALIZE => 1);
my $overlapmod = Text::Similarity::Overlaps->new (\%opt_hash);

ok ($overlapmod);
my $score = $overlapmod->getSimilarity ('GPL.txt', 'GPL.txt');
is ($score, 1, "self similarity of GPL")
