#!/usr/bin/perl -w
use strict;

die "Usage: <in_file> <min_ratio> <out_file>!\n" unless @ARGV == 3;
my $in_file = shift;
my $min_ratio = shift;
my $out_file = shift;

open OUT, " >$out_file";
open IN, $in_file;
while (<IN>) {
	chomp;
	if (/^#/) {
		print "$_\n";
		print OUT "$_\n";
		next;
	}
	my @info = (split /\t/);
	my ($alog, $log) = (0, 0);
	for (my $i = 1; $i <= 5; $i ++) {
		my ($id, $ratio, $mut) = (split /,/, $info[$i])[0,1,2];
		if ($id ne "NA" && $ratio >= $min_ratio && $mut eq "-") {
			$alog = 1;
		}
	}
	next unless $alog;
	print OUT "$_\n";
	for (my $j = 6; $j <= 53; $j ++) {
		my ($id, $ratio, $mut) = (split /,/, $info[$j])[0,1,2];
		if ($id ne "NA" && $ratio >= 30 && $mut eq "-") {
			$log = 1;
		}
	}
	unless ($log) {
		print "$_\n";
	}
}
close IN;
close OUT;
