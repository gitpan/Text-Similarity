package Text::Similarity;

use 5.006;
use strict;
use warnings;


use constant {
    COMPFILE => "compfile",
    STEM     => "stem",
    VERBOSE  => "verbose",
    STOPLIST => "stoplist"
    };

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Similarity ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

# Attributes
my %errorString;
my %compounds;
my %verbose;
my %stem;

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
	    else {
		$self->error ("Unknown option: $key");
	    }
	}
    }
    return $self;
}

sub getRelatedness
{
    my $self = shift;
    return 0;
}


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

sub loadCompounds
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

sub DESTROY
{
    my $self = shift;
    delete $errorString{$self};
    delete $compounds{$self};
    delete $stem{$self};
    delete $verbose{$self};
}

1;

__END__

=head1 NAME

Text::Similarity - module for measuring the similarity of text documents

=head1 SYNOPSIS

  use Text::Similarity;
  my $mod = Text::Similarity->new;
  my $score = $mod->getRelatedness ($text_file1, $text_file2);

=head1 DESCRIPTION

This module serves as a superclass for other modules that implement measures
of text document similarity.

=head1 SEE ALSO

Text::Similarity::Overlaps
Text::Similarity::BagOfWords

http://text-similarity.sourceforge.net

=head1 AUTHOR

Jason Michelizzi, E<lt>jmichelizzi at sourceforge.netE<gt>

Ted Pedersen, E<lt>tpederse at d.umn.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jason Michelizzi and Ted Pedersen

This library is free software; you may redistribute it and/or modify
it under the terms of the GNU General Public License, version 2 or,
at your option, any later version.

=cut
