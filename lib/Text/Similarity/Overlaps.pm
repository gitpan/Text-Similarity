package Text::Similarity::Overlaps;

use 5.006;
use strict;
use warnings;

use Text::Similarity;
use Text::OverlapFinder;

our @ISA = qw(Text::Similarity);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Similarity::Overlaps ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.04';

# information about granularity is not used now
# the would be that you could figure out similarity
# unit by unit, that is sentence by sentence, 
# paragraph by paragraph, etc. however, at this 
# point similarity is only computed document by
# document

use constant WORD      => 0;
use constant SENTENCE  => 1;
use constant PARAGRAPH => 2;
use constant DOCUMENT  => 3;

my %finder;

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new (@_);
    if ($self->stoplist) {
	$finder{$self} = Text::OverlapFinder->new(stoplist => $self->stoplist);
    }
    else {
	$finder{$self} = Text::OverlapFinder->new;
    }

    #string_compare_initialize (0, undef);
    return $self;
}


sub finder : lvalue
{
    my $self = shift;
    $finder{$self};
} 

sub DESTROY
{
    my $self = shift;
    delete $finder{$self};
}

# this method requires that the input be provided in files. 
# this is now just a front end to getSimilarityStrings that 
# does file handling. Actual similarity measuresments are
# performed between strings in getSimilarityStrings.

sub getSimilarity
{
    my $self = shift;

    # we created a separate method for getSimilarityStrings since overloading 
    # to accept both strings and file names as input parameters to 
    # getSimilarity would have required that we treat any file name that does
    # not have a corresponding file to be treated as a string, thus making it
    # impossible to really deal with missing file errors, and probably resulting
    # in quite a bit of user annoyance as 'textt1.txt' is measured for similarity
    # with the contents of 'text2.txt'

    my $file1 = shift;
    my $file2 = shift;

    # granularity is not currently supported

    my $granularity = shift;
    $granularity = DOCUMENT unless defined $granularity;

    unless (-e $file1) {
	$self->error ("The file '$file1' does not exist");
	return undef;
    }
    unless (-e $file2) {
	$self->error ("The file '$file2' does not exist");
	return undef;
    }

    unless (open (FH1, '<', $file1)) {
	$self->error ("Cannot open $file1: $!");
	return undef;
    }
    unless (open (FH2, '<', $file2)) {
	$self->error ("Cannot open $file2: $!");
	return undef;
    }
    
    my $str1;
    my $str2;
    while (<FH1>) {
	$str1 .= $self->sanitizeString ($_);
    }
    $str1 =~ s/\s+/ /g;
    while (<FH2>) {
	$str2 .= $self->sanitizeString ($_);
    }
    $str2 =~ s/\s+/ /g;

    $str1 = $self->compoundify ($str1);
    $str2 = $self->compoundify ($str2);

    close FH1;
    close FH2;

# add this call, to expose this method to users too (in case they want to
# just measure the similarity of two strings. So we have our files converted
# into strings, and now measure their similarity.

    my $score = $self -> getSimilarityStrings ($str1,$str2);

# end getSimilarity here, making sure to return similarity value from 
# get SimilarityStrings

    return $score;

}

# this method measures the similarity between two strings. If a string is empty
# or missing then we throw an exception

sub getSimilarityStrings {

    my $self = shift;

    my $input1 = shift;
    my $input2 = shift;

# check to make sure you have a string! empty file or string should be rejected

    if (!defined($input1)) {
	    $self->error ("first input string is undefined: $!");
	    return undef;
    }
    if (!defined($input2)) {
	    $self->error ("second input string is undefined: $!");
	    return undef;
    }

    # clean the strings

    my $str1 .= $self->sanitizeString ($input1);
    my $str2 .= $self->sanitizeString ($input2);

    my ($overlaps, $wc1, $wc2) = $self->finder->getOverlaps ($str1, $str2);
    my $score = 0;
    if ($self->verbose) {
	print "keys: ", scalar keys %$overlaps, "\n";
    }
    foreach my $key (sort keys %$overlaps) {
	my @words = split /\s+/, $key;

	if ($self->verbose) {
	    print "-->'$key' len(", scalar @words, ") cnt(", $overlaps->{$key}, ")\n";
	}

	#$score += scalar @words * scalar @words * ${$overlaps}{$key};
	$score += scalar @words * $overlaps->{$key};
    }

    # fix for divide by zero error, will short circuit when score is 0
    # provided by cernst at esoft.com
    # who reported via rt.cpan.org ticket 29902

    if ($score == 0){
	return $score;
	}

    # end of fix

    if ($self->normalize) {
	if ($self->verbose) {
	    print "wc 1: $wc1\n";
	    print "wc 2: $wc2\n";
	}
	my $prec = $score / $wc2;
	my $recall = $score / $wc1;
	my $f = 2 * $prec * $recall / ($prec + $recall);
	if ($self->verbose) {
	    print " Raw score: $score\n";
	    print " Precision: $prec\n";
	    print " Recall   : $recall\n";
	    print " F-measure: $f\n";
	    my $e = 1 - $f;
	    print " E-measure: $e\n";
	    my $cos = $score / sqrt ($wc1 * $wc2);
	    print " Cosine   : $cos\n";
	    my $jaccard; # intersection / union
	}
	$score = $f;
    }

    return $score;
}

sub doStop {0}

1;

__END__

=head1 NAME

Text::Similarity::Overlaps - Score the Matches Found Between Two Strings

=head1 SYNOPSIS

          # you can measure the similarity between two input strings
	  # if you don't normalize the score, you get the number of matching words
          # if you normalize, you get a score between 0 and 1 that is scaled based
	  # on the length of the strings

	  use Text::Similarity::Overlaps;
 
	  # my %options = ('normalize' => 1, 'verbose' => 1);
	  my %options = ('normalize' => 0, 'verbose' => 0);
	  my $mod = Text::Similarity::Overlaps->new (\%options);
          defined $mod or die "Construction of Text::Similarity::Overlaps failed";

          my $string1 = 'this is a test for getSimilarityStrings';
          my $string2 = 'we can test getSimilarityStrings this day';

	  my $score = $mod->getSimilarityStrings ($string1, $string2);
       	  print "The number of matching words between string1 and string2 is : $score\n";

	  # you may want to measure the similarity of a document
          # sentence by sentence - the below example shows you
	  # how - suppose you have two text files file1.txt and
          # file2.txt - each having the same number of sentences.
          # convert those files into multiple files, where each
          # sentence from each file is in a separate file. 

	  # if file1.txt and file3.txt each have three sentences, 
          # filex.txt will become sentx1.txt sentx2.txt sentx3.txt

	  # this just calls getSimilarity( ) for each pair of sentences

	  use Text::Similarity::Overlaps;
	  my %options = ('normalize' => 1, 'verbose' =>1, 'stoplist' => 'stoplist.txt');
	  my $mod = Text::Similarity::Overlaps->new (\%options);
          defined $mod or die "Construction of Text::Similarity::Overlaps failed";

	  @file1_sentences = qw / sent11.txt sent12.txt sent13.txt /;
	  @file2_sentences = qw / sent21.txt sent22.txt sent23.txt /;

          # assumes that both documents have same number of sentences 

	  for ($i=0; $i <= $#file1_sentences; $i++) {
	          my $score = $mod->getSimilarity ($file1_sentences[$i], $file2_sentences[$i]);
        	  print "The similarity of $file1_sentences[$i] and $file2_sentences[$i] is : $score\n";
	  }

	  my $score = $mod->getSimilarity ('file1.txt', 'file2.txt');
       	  print "The similarity of the two files is : $score\n";

=head1 DESCRIPTION

This module computes the similarity of two text documents or strings by searching for 
literal word token overlaps. At present comparisons are made between  entire documents, 
and finer granularity is not supported. Files are treated as one long input string, so 
overlaps can be found across sentence and paragraph boundaries. 

Files are first converted into strings by getSimilarity(), then getSimilarityStrings()  
does the actual processing. 

=head1 SEE ALSO

 L<http://text-similarity.sourceforge.net>

=head1 AUTHOR

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

Last modified by : 
$Id: Overlaps.pm,v 1.18 2008/04/04 18:30:19 tpederse Exp $

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008 by Jason Michelizzi and Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
