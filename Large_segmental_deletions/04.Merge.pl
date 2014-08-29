#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*.ort.stat> <column: e.g. 13> <cutoff: e.g. 0.8> \n" unless @ARGV == 3;
my ($file,$col,$cutoff) = @ARGV;

my ($sca_last,$be_last,$ed_last,$len,$sum,$order_a_last,$order_b_last,$n,@temp);
open (IN,$file) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	next unless ($info[$col-1] >= $cutoff);
	$n ++;
	my ($sca,$be,$ed,$order_a,$order_b) = @info[0,1,2,4,5];
	if ($n == 1) {
		($sca_last,$be_last,$ed_last,$order_a_last,$order_b_last) = ($sca,$be,$ed,$order_a,$order_b);
		next;
	}
	if ($sca_last ne $sca) {
		$len = $ed_last-$be_last+1;
		$sum = $order_b_last-$order_a_last+1;
		my $line = join "\t",$sca_last,$be_last,$ed_last,$len,$order_a_last,$order_b_last,$sum;
		print "$line\n";
		($sca_last,$be_last,$ed_last,$order_a_last,$order_b_last) = ($sca,$be,$ed,$order_a,$order_b);
		next;
	} 
	if ($order_a <= $order_b_last) {
		if ($order_b >= $order_b_last) {
			$order_b_last = $order_b;
			$ed_last = $ed;
		}
		$len = $ed_last-$be_last+1;
		$sum = $order_b_last-$order_a_last+1;
	} else {
		$len = $ed_last-$be_last+1;
		$sum = $order_b_last-$order_a_last+1;
		my $line = join "\t",$sca_last,$be_last,$ed_last,$len,$order_a_last,$order_b_last,$sum;
		print "$line\n";
		($sca_last,$be_last,$ed_last,$order_a_last,$order_b_last) = ($sca,$be,$ed,$order_a,$order_b);
	}
	
}
my $line = join "\t",$sca_last,$be_last,$ed_last,$len,$order_a_last,$order_b_last,$sum;
print "$line\n";
close IN;
