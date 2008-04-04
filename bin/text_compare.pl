#!/usr/local/bin/perl

use strict;
use warnings;
use 5.006;

use Text::Similarity;
use Getopt::Long;

sub formatNumber($);

our $VERSION = '0.05';

## these are current command line options

our ($verbose, $stem, $type, $stoplist, $help, $version, $string);

## compfile (compound file) not working, causes hang
## our ($verbose, $stem, $compfile, $type, $stoplist, $help, $version);

## normalize scores unless directed to otherwise (via --no-normalize)

our $normalize = 1;

## this will enable any of the options set on the command line
## if invalid or nonexistant options are given then we quit here

my $result = GetOptions (verbose => \$verbose, 
			 stem => \$stem,
##
## compfile option is not working, so don't enable
##			 "compfile=s" => \$compfile, 
##
			 "stoplist=s" => \$stoplist,
			 "type=s" => \$type,
##
## normalize! means that it is negatatable, so you can specify
## --no-normalize to turn it off
##
			 "normalize!" => \$normalize,
			 string => \$string,
			 version => \$version,
			 help => \$help
			 );
$result or exit 1;

if (defined $help) {
    showUsage(detailed => 1);
    exit;
}
elsif (defined $version) {
    print <<"EOT";
text_compare.pl version ${VERSION}
Copyright (C) 2004-2008, Jason Michelizzi and Ted Pedersen

This program comes with ABSOLUTELY NO WARRANTY.  This is free
software, and you are welcome to redistribute and/or modify
it under certain conditions; see the file GPL.txt for details
on copyright and warranty.
EOT

    exit;
}
elsif (!defined $type) {
    showUsage();
    exit;
}

## this style of reference to a constant is not suported
## in perl 5.6, however, will work in 5.8 and better

#my %opt_hash = (
#		Text::Similarity::STEM => $stem,
#		Text::Similarity::VERBOSE => $verbose,
#		Text::Similarity::COMPFILE => $compfile,
#		Text::Similarity::STOPLIST => $stoplist,
#		Text::Similarity::NORMALIZE => $normalize
#		);

my %opt_hash = (
		'stem' => $stem,
		'verbose' => $verbose,
		'stoplist' => $stoplist,
		'normalize' => $normalize
		);
## not working  'compfile' => $compfile,

# make sure --type is specified, otherwise end now 

eval "require $type";
if ($@) {die $@}

# if the user has input strings, let's get them and get out
# otherwise, let file handling take over

if (defined $string) {
	my $str1 = shift;
	my $str2 = shift;

	my $mod = $type->new (\%opt_hash);
	my $score = $mod->getSimilarityStrings ($str1, $str2);

	if (defined $score) {
	    print formatNumber ($score), "\n";
	}
	else {
	    my $err = $mod->error;
	    print $err, "\n";
	}
exit 0;
}

# if we aren't handling string input, fall through to here and start 
# processing files

my $file1 = shift;
my $file2 = shift;

unless (defined $file1 && defined $file2) {
    showUsage();
    exit 1;
}

# check to see that files truly exist

if (!-e $file1) {
	print STDERR "ERROR($0): 
	FILE1 ($file1) does not exist\n";
	exit;
}

if (!-e $file2) {
	print STDERR "ERROR($0): 
	FILE2 ($file2) does not exist\n";
	exit;
}

my $mod = $type->new (\%opt_hash);
my $score = $mod->getSimilarity ($file1, $file2);

if (defined $score) {
    print formatNumber ($score), "\n";
}
else {
    my $err = $mod->error;
    print $err, "\n";
}

# assume the thousands separator is ',' and the decimal is '.'
sub formatNumber ($)
{
    my $number = shift;
    $number = "$number"; # stringify
    my $idx = index $number, ".";

    my $ipart; # integer portion
    my $fpart; # fractional portion
    if ($idx >= $[) {
	$ipart = substr $number, 0, $idx;
	$fpart = substr $number, $idx + 1;
	$ipart = "0" if length ($ipart) < 1;
    }
    else {
	$ipart = $number;
	$fpart = "";
    }

    do {} while ($ipart =~ s/(?<=\d)(?<!,)(\d\d\d)(?:$|,|\.)/,$1/);
    $number = $ipart;
    $number .= ".$fpart" if length ($fpart) > 0;
    return $number;
}


sub showUsage
{
    my %optionHash = @_;
    my $detailed = 0;
    if (defined $optionHash{detailed}) {
	$detailed = 1;
    }
    print <<'EOT';
Usage: text_compare.pl [[--verbose] [--stoplist=FILE] --type=TYPE
                        [--no-normalize] FILE1 FILE2 | --string STR1 STR2 
                       | --help | --version]
EOT

    if ($detailed) {
	print <<'EOT1';

--type=TYPE       The type of measure you want to use.  Possible measures:
                      Text::Similarity::Overlaps
--verbose         Show verbose output
--stoplist=FILE   A plain text file that specifies words that should be 
		  ignored in calculating similarity. Specify one word per
                  line, avoid extra spaces after words.
--no-normalize    Do not normalize scores.  Normally, scores are normalized
                  so that they range from 0 to 1.  Using this option will
		  give you a raw score instead.
--string	  Input will be given as strings rather than files.
--help            Show this help message
--version         Show version information.
EOT1
    }
}

__END__

=head1 NAME

text_compare.pl - Measure the similarity between files or strings

=head1 SYNOPSIS

 text_compare.pl --type Text::Similarity::Overlaps --normalize --string '.......this is one' '????this is two' 

 text_compare.pl --type Text::Similarity::Overlaps --no-normalize --string '.......this is one' '????this is two' 

 text_compare.pl --type Text::Similarity::Overlaps --string 'sir winston churchill' 'Churchill, Winston Sir' 

 text_compare.pl --type Text::Similarity::Overlaps ../GPL.txt ../FDL.txt

 text_compare.pl --verbose --type Text::Similarity::Overlaps ../GPL.txt ../FDL.txt 

 text_compare.pl --verbose --stoplist stoplist.txt --type Text::Similarity::Overlaps ../GPL.txt ../FDL.txt 

 text_compare.pl [[--verbose] [--stoplist=FILE] [--no-normalize] [--string]] --type=TYPE | --help | --version] FILE1 FILE2

=head1 DESCRIPTION

This script is a simple command-line interface to the Text::Similarity
Perl modules. At present only one method of computing similarity is 
provided, Text::Similarity::Overlaps. However, additional methods can be 
added. The output described below for this program comes from 
Text::Similarity::Overlaps, but could vary in future as additional 
similarity measurement methods are added. 

By default Text::Similarity::Overlaps returns a normalized F-measure 
between 0 and 1. Normalization can be turned off by specifying 
--no-normalize.

In addition, it can return the cosine, E-measure, precision, and recall 
when used in the verbose mode (specify --verbose in the command line). 

 precision = raw_score / length_file_2
 recall = raw_score / length_file_1
 F-measure = 2 * precision * recall / (precision + recall)
 E-measure = 1 - F-measure
 cosine = raw_score / sqrt (precision + recall) 

Files are treated as one long line of text. 

There is some cleaning of text performed automatically, which includes removal of most 
punctuation except embedded apostrophies and underscores. All text is made lower case. 
This occurs both for file and string input. 

=head1 OPTIONS

=over

=item B<--type>=I<TYPE>

The type of text similarity measure.  Valid values include:

    Text::Similarity::Overlaps

=item B<--stoplist>=I<FILE>

The name of a file containing stop words (one word per line). 

=item B<--no-normalize>

Do not normalize scores.  Normally, scores are normalized so that they range
from 0 to 1.  Using this option will give you a raw score instead.

=item B<--string>

Input will be provided on the command line as strings, not files. 

=item B<--verbose>

Show all the matches that are found between the files, their length and 
frequency, as well as precision, recall, F-measure, E-measure, and cosine.

=item B<--help>

Show a detailed help message.

=item B<--version>

Show version information.

=back

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Jason Michelizzi

Last modified by:
$Id: text_compare.pl,v 1.15 2008/04/04 18:30:17 tpederse Exp $

=head1 BUGS

=over

=item --compfile is not working, seems to cause hang (tdp 3/21/08)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2008, Jason Michelizzi and Ted Pedersen

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

