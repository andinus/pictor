#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';
use OpenBSD::Pledge;
use OpenBSD::Unveil;

# Inititalize pledge.
pledge( qw( stdio rpath unveil ) ) or
    die "Unable to pledge: $!";

# $term will store the user input.
my $term;

# User must pass at least one argument.
die "usage: pictor term\n" if
    @ARGV < 1;

# Assume first argument to be term.
$term = $ARGV[0];

# User can rename this program to "wtf" & run "wtf is wtf" instead of
# "wtf wtf", "wtf is term" looks better so we use $ARGV[1] as $term if
# $ARGV[0] is "is".
$term = $ARGV[1] if
    $ARGV[0] eq "is";

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

# Drop unveil permission.
pledge( qw( stdio rpath ) ) or
    die "Unable to pledge: $!";

# $total_acronyms will hold the total number of acronyms we find.
my $total_acronyms = 0;

# Search for acronym in every file.
foreach my $fn (@files) {
    open my $fh, '<', $fn or
        # The program should continue if the file doesn't exist but
        # warn the user about it.
        do {
            warn "Unable to open $fn: $!\n";
            next;
    };

    while (my $line = readline $fh) {
        # \Q is quotemeta, \E terminates it because otherwise it would
        # mess with \t. This regex matches when $line starts with
        # "$term\t". We replace \t with ": " before printing to make
        # the input neat.
        if ($line =~ /^\Q${term}\E\t/i) {
            print $line =~ s/\t/: /r;
            $total_acronyms++;
        }
    }
}

# Drop rpath permission.
pledge( qw( stdio ) ) or
    die "Unable to pledge: $!";

# Die if we don't find any match.
die "I don't know what '$term' means!\n" unless
    $total_acronyms;

# Drop pledge permissions.
pledge() or
    die "Unable to pledge: $!";
