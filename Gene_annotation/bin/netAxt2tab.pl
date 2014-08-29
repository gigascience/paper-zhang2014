#!/usr/bin/perl

#2011.08.05

if (@ARGV != 2)
{
	print "perl $0 <.netAxt> <target.len>\n";
	exit;
}

use strict;

my $net = shift;
my $len = shift;

my %chr_len;
&read_len($len,\%chr_len); #sub 1

&netAxt_2_table($net,\%chr_len); #sub 2



## sub 1
##
sub read_len
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die;
	while (<IN>)
	{
		my ($chr,$len) = (split)[0,1];
		$hshp->{$chr} = $len;
	}
	close IN;
}


## sub 2
##
sub netAxt_2_table
{
	my $file = shift;
	my $hshp = shift;
	
	my ($out1,$out2);
	open IN, $file or die;
	$/ = "\n\n";
	while (<IN>)
	{
		my $ln = (split /\n/,$_)[-3];
		my ($id,$chr1,$bg1,$end1,$chr2,$bg2,$end2,$strand) = (split /\s+/,$ln)[0,1,2,3,4,5,6,7];
		$out1 .= "$chr1\t$chr1.$id\t$bg1\t$end1\n";
		if ($strand eq "+")
		{
			$out2 .= "$chr2\t$chr2.$chr1.$id\t$bg2\t$end2\n";
		}elsif ($strand eq "-")
		{
			my $start = $hshp->{$chr2} - $end2 + 1;
			my $end   = $hshp->{$chr2} - $bg2 + 1;
			$out2 .= "$chr2\t$chr2.$chr1.$id\t$start\t$end\n";
		}else
		{
			print STDERR "Wrong:  \n\n$ln\n";
		}
	}
	close IN;
	$/ = "\n";
	
	open IN,">$file.target.tab" or die;
	print IN $out1;
	close IN;

        open IN,">$file.query.tab" or die;
        print IN $out2;
        close IN;
}
