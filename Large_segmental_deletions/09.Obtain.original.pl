#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*.nr.mix.stat.right> <*nr>\n" unless @ARGV == 2;

my %hash;
open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	my ($aa,$bb) = @info[4,5];
	push @{$hash{$info[0]}}, [$aa,$bb];
}
close IN;

open (IN,$ARGV[1]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	if (exists $hash{$info[0]}) {
		my $flag = 0;
		foreach my $ref (@{$hash{$info[0]}}) {
			my ($aa,$bb) = @{$ref};
			unless ($info[4] >$bb || $info[5] < $aa)  {
				$flag = 1;
				last;
			}
		}
		print $_,"\n" if ($flag == 0);

	} else {
		print $_,"\n";
	}
}
close IN;

