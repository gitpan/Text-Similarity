package Text::Similarity::Overlaps;

use 5.006;
use strict;
use warnings;

require Exporter;

use Text::Similarity;
#use WordNet::Similarity;
#use string_compare;

our @ISA = qw(Text::Similarity);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Similarity::overlaps ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

use constant {
    WORD      => 0,
    SENTENCE  => 1,
    PARAGRAPH => 2,
    DOCUMENT  => 3
};

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new (@_);
    #string_compare_initialize (0, undef);
    return $self;
}

sub getRelatedness
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


    if ($self->verbose) {
	open OFH1, '>', "str1.txt" or die "Cannot open str1.txt: $!";
	open OFH2, '>', "str2.txt" or die "Cannot open str2.txt: $!";

	print OFH1 $str1;
	print OFH2 $str2;

	close OFH1;
	close OFH2;
    }

    #my %overlaps = string_compare_getStringOverlaps ($str1, $str2);
    my $overlaps = getStringOverlaps ($str1, $str2);

    my $score = 0;
    if ($self->verbose) {
	print "keys: ", scalar keys %$overlaps, "\n";
	print "-" x 10, "\n";
    }
    foreach my $key (keys %$overlaps) {
	my @words = $key =~ /(\w+)/g;

	if ($self->verbose) {
	    print $key, " ", scalar @words, "\n";
	    print "-" x 10, "\n";
	}

	$score += scalar @words * scalar @words * ${$overlaps}{$key};
    }

    return $score;
}

sub doStop {0}

# adapted from a function in string_compare.pm (distributed with
# WordNet::Similarity)
sub getStringOverlaps
{
    my $string0 = shift;
    my $string1 = shift;
    my %overlapsHash = ();

    $string0 =~ s/^\s+//;
    $string0 =~ s/\s+$//;
    $string1 =~ s/^\s+//;
    $string1 =~ s/\s+$//;

    # if stemming on, stem the two strings
    my $stemmingReqd = 0;
    if ($stemmingReqd)
    {
	my $stemmer = bless [];
        $string0 = $stemmer->stemString($string0, 1); # 1 turns on cacheing
        $string1 = $stemmer->stemString($string1, 1);
    }

    my @words = split /\s+/, $string0;

    # for each word in string0, find out how long an overlap can start from it.
    my @overlapsLengths = ();
    my $matchStartIndex = 0;
    my $currIndex = -1;

    while ($currIndex < $#words)
    {
        # forward the current index to look at the next word
        $currIndex++;

        # form the string
        my $temp = join (" ", @words[$matchStartIndex...$currIndex]);

        # if this works, carry on!
        next if ($string1 =~ /\b\Q$temp\E\b/);

        # otherwise store length is $overlapLengths[$matchStartIndex];
        $overlapsLengths[$matchStartIndex] = $currIndex - $matchStartIndex;
        $currIndex-- if ($overlapsLengths[$matchStartIndex] > 0);
        $matchStartIndex++;
    }

    for (my $i = $matchStartIndex; $i <= $currIndex; $i++)
    {
        $overlapsLengths[$i] = $currIndex - $i + 1;
    }

    my ($longestOverlap) = sort {$b <=> $a} @overlapsLengths;
    while (defined($longestOverlap) && ($longestOverlap > 0))
    {
        for (my $i = 0; $i <= $#overlapsLengths; $i++)
        {
            next if ($overlapsLengths[$i] < $longestOverlap);

            # form the string
            my $stringEnd = $i + $longestOverlap - 1;
            my $temp = join (" ", @words[$i...$stringEnd]);

            # check if still there in $string1. replace in string1 with a mark

            if (!doStop($temp) && $string1 =~ s/\Q$temp\E/XXX/)
            {
                # so its still there. we have an overlap!
                $overlapsHash{$temp}++;

                # adjust overlap lengths forward
                for (my $j = $i; $j < $i + $longestOverlap; $j++)
                {
                    $overlapsLengths[$j] = 0;
                }

                # adjust overlap lengths backward
                for (my $j = $i-1; $j >= 0; $j--)
                {
                    last if ($overlapsLengths[$j] <= $i - $j);
                    $overlapsLengths[$j] = $i - $j;
                }
            }
            else
	    {
                # ah its not there any more in string1! see if
                # anything smaller than the full string works
                my $k = $longestOverlap - 1;
                while ($k > 0)
                {
                    # form the string
                    my $stringEnd = $i + $k - 1;
                    my $temp = join (" ", @words[$i...$stringEnd]);

                    last if ($string1 =~ /\b\Q$temp\E\b/);
                    $k--;
                }

                $overlapsLengths[$i] = $k;
            }
        }
        ($longestOverlap) = sort {$b <=> $a} @overlapsLengths;
    }
    return \%overlapsHash;
}


1;

__END__


=head1 NAME

Text::Similarity::overlaps - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Text::Similarity;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Text::Similarity, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jason Michelizzi, E<lt>jmichelizzi at sourceforge.netE<gt>

Ted Pedersen, E<lt>tpederse at d.umn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jason Michelizzi and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License.


=cut
