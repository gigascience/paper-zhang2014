#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*nr.mix.stat> <column: e.g. 13> <cutoff: e.g. 0.8> \n" unless @ARGV == 3;
my ($file,$col,$cutoff) = @ARGV;

open (IN,$file) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\t/;
	next unless( ($info[8] <0.5) && ($info[10]<0.5) && ($info[$col-1] >= $cutoff));
	my $line = join "\t",@info[0..6];
	print "$line\n";
}
close IN;
