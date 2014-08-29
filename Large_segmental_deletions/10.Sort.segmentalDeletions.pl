#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*.nr> <all.list> \n" unless @ARGV == 2;
my (@record,%nr);
open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	if (exists $nr{$info[0]}) {
		
	} else {
		$nr{$info[0]} = 1;
		push @record,$info[0];
	}
}
close IN;

my %all;
open (IN,$ARGV[1]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	$all{$info[0]}{$info[1]} = $_;
}
close IN;


foreach my $chr (@record) {
	foreach my $star (sort {$a<=>$b} keys %{$all{$chr}}) {
		print "$all{$chr}{$star}\n";
	}
}
