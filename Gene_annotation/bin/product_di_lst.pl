#!/usr/bin/perl 

use strict;

die "Usage:
	perl $0 <gff> >outfile\n" if @ARGV < 1;

my $file=shift;
open IN,$file or die $!;
while(<IN>){
	next if /^\s|#/;
	next unless /mRNA/;
	my $id=$1 if /ID=([^;]+)/;
	my $p_id=$id;
	$p_id=$1 if $id=~/([\S]+)-D\S+/;
	print "$id\t$p_id\n";
}
close IN;
