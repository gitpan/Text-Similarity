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

our $VERSION = '0.03';

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

sub getSimilarity
{
    my $self = shift;
    my $file1 = shift;
    my $file2 = shift;
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

Text::Similarity::Overlaps

=head1 SYNOPSIS

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

This module computes the similarity of two text documents by searching
for literal word token overlaps. At present comparisons are made between 
entire documents, and finer granularity is not supported. Files are 
treated as one long input string, so overlaps can be found across 
sentence and paragraph boundaries. 

=head1 SEE ALSO

=head1 AUTHOR

Ted Pedersen, University of Minnesota, Duluth
tpederse at d.umn.edu

Jason Michelizzi

Last modified by : 
$Id: Overlaps.pm,v 1.15 2008/03/21 22:21:11 tpederse Exp $

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
