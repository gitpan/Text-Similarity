#!/usr/local/bin/perl

use strict;
use warnings;
use 5.006;

use Text::Similarity;
use Getopt::Long;

sub formatNumber($);

our $VERSION = '0.01';

our ($verbose, $stem, $compfile, $type, $stoplist, $help);

our $normalize = 1;

my $result = GetOptions (verbose => \$verbose, stem => \$stem,
			 "compfile=s" => \$compfile,
			 "stoplist=s" => \$stoplist,
			 "type=s" => \$type,
			 "normalize!" => \$normalize,
			 help => \$help);

$result or exit 1;

if ($help) {
    showUsage(detailed => 1);
    exit;
}
elsif (!defined $type) {
    showUsage();
    exit;
}

if ($normalize) {
    print "Normalizing...\n"
}

my %opt_hash = (
		Text::Similarity::STEM => $stem,
		Text::Similarity::VERBOSE => $verbose,
		Text::Similarity::COMPFILE => $compfile,
		Text::Similarity::STOPLIST => $stoplist,
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


my $score = $mod->getRelatedness ($file1, $file2);

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
    do {} while ($number =~ s/(?<=\d)(?<!,)(\d\d\d)(?:$|,|\.)/,$1/);
    return $number;
}


sub showUsage
{
    my %optionHash = @_;
    if (defined $optionHash{detailed}) {
	print STDERR "No detailed usage available yet\n";
	print STDERR "Try running perldoc on this file\n";
    }
    else {
	print <<'EOT';
Usage: text_compare.pl [[--verbose] [--compfile=FILE] [--stem] --type=TYPE
                  | --help | --version] FILE1 FILE2
EOT
    }
}

__END__

=head1 NAME

text_compare.pl - simple command-line interface to Text::Similarity

=head1 SYNOPSIS

text_compare.pl [[--verbose] [--compfile=FILE] [--stem] --type=TYPE | --help | --version] FILE1 FILE2

=head1 DESCRIPTION

This script is a simple command-line interface to the Text::Similarity
set of Perl modules.

=head1 OPTIONS

B<--type>=I<TYPE>

The type of text similarity measure.  Valid values include:

    Text::Similarity::Overlaps

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

