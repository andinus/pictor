#!/usr/bin/perl

use strict;
use warnings;

use constant is_OpenBSD => $^O eq "openbsd";
if (is_OpenBSD) {
    require OpenBSD::Unveil;
    OpenBSD::Unveil->import;

    require OpenBSD::Pledge;
    OpenBSD::Pledge->import;
} else {
    sub unveil { return 1; }
    sub pledge { return 1; }
}

# Inititalize pledge.
pledge( qw( stdio rpath unveil ) )
    or die "Unable to pledge: $!";

# User must pass at least one argument.
die "usage: pictor term\n"
    unless @ARGV > 0;

my $term = $ARGV[0];

# Ignore "is" operand if it's passed.
if ( $ARGV[0] eq "is"
         and @ARGV > 1 ) {
    $term = $ARGV[1];
}

# files contains list of all files to search for acronyms.
my @files = (
    '/usr/local/share/misc/acronyms',
    '/usr/local/share/misc/acronyms-o',
    '/usr/local/share/misc/acronyms.comp',
);

# Unveil each file with only read permission.
foreach my $fn (@files) {
    unveil( $fn, "r" )
        or die "Unable to unveil: $!";
}

# Block further unveil calls.
unveil()
    or die "Unable to lock unveil: $!";

# Drop unveil permission.
pledge( qw( stdio rpath ) )
    or die "Unable to pledge: $!";

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
pledge( qw( stdio ) )
    or die "Unable to pledge: $!";

# die if no match is found.
die "I don't know what '$term' means!\n"
    unless $total_acronyms;

# Drop pledge permissions.
pledge()
    or die "Unable to pledge: $!";
