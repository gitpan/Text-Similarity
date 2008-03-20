package Text::Similarity;

use 5.006;
use strict;
use warnings;

use constant COMPFILE => "compfile";
use constant STEM     => "stem";
use constant VERBOSE  => "verbose";
use constant STOPLIST => "stoplist";
use constant NORMALIZE => "normalize";

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';

# Attributes -- these all have lvalue accessor methods, use those methods
# instead of accessing directly.  If you add another attribute, be sure
# to take the appropriate action in the DESTROY method; otherwise, a memory
# leak could occur.

my %errorString;
my %compounds;
my %verbose;
my %stem;
my %normalize;
my %stoplist;

sub new
{
    my $class = shift;
    my $hash_ref = shift;
    $class = ref $class || $class;
    my $self = bless [], $class;

    if (defined $hash_ref) {
	while (my ($key, $val) = each %$hash_ref) {
	    if (($key eq COMPFILE) and (defined $val)) {
		$self->loadCompounds ($val);
	    }
	    elsif ($key eq STEM) {
		$self->stem = $val;
	    }
	    elsif ($key eq VERBOSE) {
		$self->verbose = $val;
	    }
	    elsif ($key eq NORMALIZE) {
		$self->normalize = $val;
	    }
	    elsif ($key eq STOPLIST) {
		$self->stoplist = $val;
	    }
	    else {
		$self->error ("Unknown option: $key");
	    }
	}
    }
    return $self;
}

sub DESTROY
{
    my $self = shift;
    delete $errorString{$self};
    delete $compounds{$self};
    delete $stem{$self};
    delete $verbose{$self};
    delete $normalize{$self};
    delete $stoplist{$self};
}

#sub _loadStoplist
#{
#    my $self = shift;
#    my $file = shift;
#
#    unless (open FH, '<', $file) {
#	$self->error ("Cannot open '$file': $!");
#	return undef;
#    }
#
#    while (<FH>) {
#	chomp;
#	my $word = lc;
#	$stoplist{$self}->{$word} = 1;
#    }
#
#    close FH;
#}

sub error
{
    my $self = shift;
    my $msg = shift;
    if ($msg) {
	my ($package, $file, $line) = caller;
	$errorString{$self} .= "\n" if $errorString{$self};
	$errorString{$self} .= "($file:$line) $msg";
    }
    return $errorString{$self};
}

sub verbose : lvalue
{
    my $self = shift;
    $verbose{$self}
}

sub stem : lvalue
{
    my $self = shift;
    $stem{$self}
}

sub normalize : lvalue
{
    my $self = shift;
    $normalize{$self}
}

sub sanitizeString
{
    my $self = shift;
    my $str = shift;

    # get rid of most punctuation
    $str =~ tr/.;:,?!(){}\x22\x60\x24\x25\x40<>/ /s;

    # convert to lower case
    $str =~ tr/A-Z_/a-z /;

    # convert ampersands into 'and' -- maybe not appropriate?
    # s/\&/ and /;

    # get rid of apostrophes not surrounded by word characters
    $str =~ s/(?<!\w)\x27/ /g;
    $str =~ s/\x27(?!\w)/ /g;

    # get rid of dashes, but not hyphens
    $str =~ s/--/ /g;

    # collapse consecutive whitespace chars into one space
    $str =~ s/\s+/ /g;
    return $str;
}

sub stoplist : lvalue
{
    my $self = shift;
    $stoplist{$self}
}

sub _loadCompounds
{
    my $self = shift;
    my $compfile = shift;

    unless (open FH, '<', $compfile) {
	$self->error ("Cannot open '$compfile': $!");
	return undef;
    }
    
    while (<FH>) {
	chomp;
	$compounds{$self}{$_} = 1;
    }

    close FH;
}

sub removeStopWords
{
    my $self = shift;
    my $str = shift;
    foreach my $stopword (keys %{$self->stoplist}) {
	$str =~ s/\Q $stopword \E/ /g;
    }
    return $str;
}

# compoundifies a block of text
# e.g., if you give it "we have a new bird dog", you'll get back
# "we have a new bird_dog".
# (code borrowed from rawtextFreq.pl)
sub compoundify
{
    my $self = shift;
    my $block = shift; # get the block of text
    my $done;
    my $temp;

    unless ($compounds{$self}) {
	return $block;
    }

    # get all the words into an array
    my @wordsArray = $block =~ /(\w+)/g;

    # now compoundify, GREEDILY!!
    my $firstPtr = 0;
    my $string = "";

    while($firstPtr <= $#wordsArray)
    {
        my $secondPtr = $#wordsArray;
        $done = 0;
        while($secondPtr > $firstPtr && !$done)
        {
            $temp = join ("_", @wordsArray[$firstPtr..$secondPtr]);
            if(exists $compounds{$self}{$temp})
            {
                $string .= "$temp ";
                $done = 1;
            }
            else
            {
                $secondPtr--;
            }
        }
        if(!$done)
        {
            $string .= "$wordsArray[$firstPtr] ";
        }
        $firstPtr = $secondPtr + 1;
    }
    $string =~ s/ $//;

    return $string;
}



1;

__END__

=head1 NAME

Text::Similarity - module for measuring the similarity of text documents.
This module is a superclass for other modules.

=head1 SYNOPSIS
 
  # this will return an un-normalized score that just gives the 
  # number of overlaps - this is same synopsis as in Text/Overlaps.pm

  use Text::Similarity::Overlaps;
  my $mod = Text::Similarity::Overlaps->new;
  defined $mod or die "Construction of Text::Similarity::Overlaps failed";
  
  # adjust file names to reflect true relative position
  # these paths are valid from lib/Text/
  my $text_file1 = '../../t/test1.txt';
  my $text_file2 = '../../t/test2.txt';

  my $score = $mod->getSimilarity ($text_file1, $text_file2);
  print "The similarity of $text_file1 and $text_file2 is : $score\n";

=head1 DESCRIPTION

This module serves as a superclass for other modules that implement measures
of text document similarity.

=head1 SEE ALSO

=head1 AUTHOR

Ted Pedersen, University of Minnesota, Duluth
tpederse at d.umn.edu

Siddharth Patwardhan
sidd at cs.utah.edu

Jason Michelizzi

Last modified by :
$Id: Similarity.pm,v 1.10 2008/03/20 01:41:44 tpederse Exp $

=head1 COPYRIGHT AND LICENSE

Text::Similarity
Copyright (C) 2004-2008, Ted Pdersen, Jason Michelizzi, and Siddharth 
Patwardhan

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
