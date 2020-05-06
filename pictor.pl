#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use OpenBSD::Pledge;
use OpenBSD::Unveil;

pledge( qw( rpath unveil ) ) or
    die "Unable to pledge: $!";

# $term will store the user input.
my $term;

# User must pass at least one argument.
if (@ARGV < 1) {
    say STDERR "usage: wtf.pl term";
    exit 1;
} else {
    $term = $ARGV[0];

    # User can rename this program to "wtf" & run "wtf is wtf" too
    # instead of "wtf wtf" or "pictor wtf", "wtf is term" looks
    # better.
    $term = $ARGV[1] if
	($ARGV[0] eq "is")
}

# files contains list of all files to search for acronyms.
my @files = (
    '/usr/local/share/misc/acronyms',
    '/usr/local/share/misc/acronyms-o',
    '/usr/local/share/misc/acronyms.comp'
    );

# Unveil each file with only read permission.
foreach my $fn (@files) {
    unveil( $fn, "r" ) or
    	die "Unable to unveil: $!";
}

# Block further unveil calls.
unveil() or
    die "Unable to lock unveil: $!";

# drop pledge permissions
pledge( qw( rpath )) or
    die "Unable to pledge: $!";

# Search for acronym in every file.
foreach my $fn (@files) {
    open my $fh, '<', $fn or
	# The program should continue if the file doesn't exist but
	# warn the user about it.
	do {
	    warn "Unable to open $fn: $!";
	    next;
    };

    while (my $line = readline $fh) {
	# \Q is quotemeta, \E terminates it because otherwise it would
	# mess with \t. This regex matches when $line starts with
	# "$term\t". We replace \t with ": " before printing to make
	# the input neat.
	print $line =~ s/\t/: /r if
	    ($line =~ /^\Q${term}\E\t/i);
    }
}

# drop pledge permissions
pledge() or
    die "Unable to pledge: $!";
