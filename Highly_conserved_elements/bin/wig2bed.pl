#!/usr/bin/perl
use warnings;

#$cutoff = 0;
my ($chrom, $start, $counter);

while(<>){
	chomp;

	print STDERR $.,"\n" if($. % 1000000 == 0);

	if(/chrom/){	
		my @line = split/\s+/;
		($chrom = $line[1]) =~ s/chrom=//;
		($start = $line[2]) =~ s/start=//;
		$counter=0;
	}else{
#		if($_ > $cutoff){
			my $coord = $start + $counter;
			print join "\t",$chrom, $coord, $coord+1, $_."\n";
#		}
		$counter++;
	}
}
