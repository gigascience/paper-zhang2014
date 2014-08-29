#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*ort.stat.opt> <column>  \n" unless @ARGV == 2;
my $col = $ARGV[1] - 1;

open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	next unless( ($info[$col] == 0) && ( ($info[9] > 0 && $info[8] < 0.5) || ($info[12] > 0 && $info[11] < 0.5) ) );
	my @temp;
	for (my $i=7;$i<@info;) {
		push @temp,$info[$i],$info[$i+1];
		$i += 3;
	}
	my $line = join "\t",@info[0..6],@temp;
	print "$line\n";
}
close IN;
