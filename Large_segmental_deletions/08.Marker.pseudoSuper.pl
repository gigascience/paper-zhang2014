#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*.nr.mix.stat.right> <*nr.mix> \n" unless @ARGV == 2;

my %hash;
open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	$hash{$info[0]}{$info[1]}{$info[2]} = 1;
}
close IN;

open (IN,$ARGV[1]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	my $line;
	if (exists $hash{$info[0]}{$info[1]}{$info[2]}) {
		$line = join "\t","1",@info;
	} else {
		$line = join "\t","0",@info;
	}
	print "$line\n";
}
close IN;

