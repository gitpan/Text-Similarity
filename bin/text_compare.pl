#!/usr/local/bin/perl

# text_compare.pl
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

use strict;
use warnings;
use 5.006;

use Text::Similarity;
use Getopt::Long;

sub formatNumber($);

our $VERSION = '0.02';

our ($verbose, $stem, $compfile, $type, $stoplist, $help, $version);

our $normalize = 1;

my $result = GetOptions (verbose => \$verbose, stem => \$stem,
			 "compfile=s" => \$compfile,
			 "stoplist=s" => \$stoplist,
			 "type=s" => \$type,
			 "normalize!" => \$normalize,
			 version => \$version,
			 help => \$help
			 );

$result or exit 1;

if ($help) {
    showUsage(detailed => 1);
    exit;
}
elsif ($version) {
    print <<"EOT";
text_compare.pl version ${VERSION}
Copyright (C) 2004, Jason Michelizzi and Ted Pedersen

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

my %opt_hash = (
		Text::Similarity::STEM => $stem,
		Text::Similarity::VERBOSE => $verbose,
		Text::Similarity::COMPFILE => $compfile,
		Text::Similarity::STOPLIST => $stoplist,
		Text::Similarity::NORMALIZE => $normalize
		);

my $file1 = shift;
my $file2 = shift;
unless (defined $file1 && defined $file2) {
    showUsage();
    exit 1;
}

eval "require $type";
if ($@) {die $@}

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
                        [--no-normalize] FILE1 FILE2
                       | --help | --version]
EOT

    if ($detailed) {
	print <<'EOT1';

--type=TYPE       The type of measure you want to use.  Possible measures:
                      Text::Similarity::Overlaps
--verbose         Show verbose output
--stoplist=FILE   The name of a file containing stop words.
--no-normalize    Do not normalize scores.  Normally, scores are normalized
                  so that they range from 0 to 1.  Using this option will
		  give you a raw score instead.
--help            Show this help message
--version         Show version information.
EOT1
    }
}

__END__

=head1 NAME

text_compare.pl - simple command-line interface to Text::Similarity

=head1 SYNOPSIS

text_compare.pl [[--verbose] [--stoplist=FILE] [--no-normalize] --type=TYPE | --help | --version] FILE1 FILE2

=head1 DESCRIPTION

This script is a simple command-line interface to the Text::Similarity
set of Perl modules.

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

=item B<--verbose>

Be verbose.

=item B<--help>

Show a detailed help message.

=item B<--version>

Show version information.

=back

=head1 AUTHORS

Jason Michelizz E<lt>jmichelizzi at gmail.comE<gt>

Ted Pedersen E<lt>tpederse at d.umn.eduE<gt>

=head1 BUGS

Probably

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, Jason Michelizzi and Ted Pedersen

This program is free software; you may redistribute and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

=cut

