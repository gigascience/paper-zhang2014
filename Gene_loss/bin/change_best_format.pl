#!/usr/bin/perl -w
use strict;

die "Usage: <in_file>!\n" unless @ARGV == 1;
my $in_file = shift;

open IN, $in_file;
while (<IN>) {
	chomp;
	if (/^#/) {
		print "$_\n";
		next;
	}
	my @info = (split /\t/);
	for (my $i = 1;$i < 54;$i ++) {
		my ($hit, $ratio, $mut) = (split /,/, $info[$i])[0,1,2];
		my $type;
		if ($hit ne "NA") {
			$type = "A";
		} else {
			if ($ratio > 0) {
				$type = "B";
			} else {
				$type = "C";
			}
		}
		$ratio = sprintf "%.2f", $ratio;
		if ($mut ne "-") {
			my $fn = $mut =~ s/F/F/g;
			my $sn = $mut =~ s/S/S/g;
			if ($fn && !$sn) {
				$mut = "${fn}F";
			} elsif (!$fn && $sn) {
				$mut = "${sn}S";
			} elsif ($fn && $sn) {
				$mut = "${fn}F${sn}S";
			}
		}
		$info[$i] = "$type,$ratio,$mut";
	}
	my $line = join("\t", @info);
	print "$line\n";
}
close IN;


