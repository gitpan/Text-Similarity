package Text::Similarity::Overlaps;

# Text::Similarity::Overlaps
# Copyright (C) 2004, Jason Michelizzi and Ted Pedersen

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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

our $VERSION = '0.02';

use constant {
    WORD      => 0,
    SENTENCE  => 1,
    PARAGRAPH => 2,
    DOCUMENT  => 3
};

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

Text::Similarity::Overlaps - module for computing the similarity of text
documents using literal string (word token) overlaps

=head1 SYNOPSIS

  use Text::Similarity::Overlaps;
  my $module = Text::Similarity::Overlaps->new;
  my $score = $module->getSimilarity ($file1, $file2);

=head1 DESCRIPTION

This module computes the similarity of two text documents by searching
for literal word token overlaps in the two documents.  The score is based
on the F-measure and ranges between 0 and 1.

=head1 SEE ALSO

Text::Similarity, Text::OverlapFinder, text_compare.pl

=head1 AUTHOR

Jason Michelizzi, E<lt>jmichelizzi at sourceforge.netE<gt>

Ted Pedersen, E<lt>tpederse at d.umn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jason Michelizzi and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License.

=cut
