#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*nr> \n" unless @ARGV == 1;
open (IN,$ARGV[0]) or die $!;

my $flag = 1;
my $first = <IN>;
chomp $first;
my @mes = split /\s+/,$first;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	if ($mes[0] ne  $info[0]) {
		my $line = join "\t",@mes;
		print "$line\n" if ($flag == 0);
		@mes = @info;
		$flag = 1;
	} else {
		if ($info[4]-$mes[5]<=10) {
			$mes[2] = $info[2];
			$mes[3] = $info[2] - $mes[1] + 1;
#			my $record = $mes[5];
			my $record = $info[4];
			$mes[5] = $info[5];
			$mes[6] = $info[5] - $mes[4] + 1;
			$flag = 0;
			push @mes,$record;
		} else {
			my $line = join "\t",@mes;
			print "$line\n" if ($flag == 0);
			@mes = @info;
			$flag = 1;
		}
	}
}
close IN;

my $result = join "\t",@mes;
print "$result\n" if ($flag == 0);
