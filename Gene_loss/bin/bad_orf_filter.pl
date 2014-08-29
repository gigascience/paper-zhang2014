#!/usr/bin/perl -w
use strict;
die "Usage: <homolog.gff> <cds.check>\n" unless @ARGV == 2;
my ($gff_file, $check_file) = @ARGV;

my %gffFile;
&readGff($gff_file, \%gffFile);

## get the number of premature stop codons of each gene.
my %preStops;
if ($check_file =~ /\.gz$/) {
	open IN, "gunzip -c $check_file | ";
} else {
	open IN, $check_file;
}
while (<IN>) {
	next if /^#/;
	my @info = split /\s+/;
	$preStops{$info[0]} = $info[3];
}
close IN;

## get the number of frameshifts of each gene.
my %frameshift;
if ($gff_file =~ /\.gz$/) {
	open IN, "gunzip -c $gff_file | ";
} else {
	open IN, $gff_file;
}
while (<IN>) {
	my @info = split /\s+/;
	next unless $info[2] eq "mRNA";
	die unless $info[8] =~ /^ID=(\S+?);Shift=(\d+?);/;
	my ($id, $fs) = ($1, $2);
	#print "$id\t$fs\n";
	$frameshift{$id} = $fs;
}
close IN;

foreach my $id (sort keys %gffFile) {
	my $ps = $preStops{$id};
	my $fs = $frameshift{$id};
	next if $ps + $fs >= 3;
	#print "$id\t$ps\t$fs\n";
	print $gffFile{$id};
}

##########################################################################################
##################################### subroutine #########################################
##########################################################################################
sub readGff {
	my ($in_file, $ref1) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		my @info = split /\s+/;
		my $id;
		die unless $info[8] =~ /^ID=\S+?;/ || $info[8] =~ /^Parent=\S+?;/;
		if ($info[8] =~ /^ID=(\S+?);/) {
			$id = $1;
		} elsif ($info[8] =~ /^Parent=(\S+?);/) {
			$id = $1;
		} else {
			die;
		}
		$ref1->{$id} .= $_;
	}
	close IN;
}
