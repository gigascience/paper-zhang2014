#!/user/bin/perl

my $depth=shift; #gap read depth file.
my $file=shift; #gap seq file.
use strict;

my %depth;
open IN,$depth;
while(<IN>)
{
	chomp;
	my @t=split /\t/;
	$depth{$t[0]}=$t[2];
}
close IN;
my $readlen=100;
my $uncovernum=0;
#print "gap\tlen\tbefore\tbs\tbe\tafter\tas\tae\n";
open IN,$file;
while(<IN>)
{
	chomp;
	#135     352     26      352     0.0738636363636364      113     209     0       375
	#>gap1915        105     97      scaffold6       0       1615    201
	my @t=split /\t/;
	my $before=$t[5];
	my $after=$t[6];
	my $id;
	if($t[0]=~/>(\S+)/)
	{
		$id=$1;
	}else{
		$id=$t[0];
	}
	my ($bs, $be, $as, $ae);
	if($t[1] > 150)
	{
		my @pos = GetRegion(500, $readlen, $t[1], $t[5], $t[6]);
		
		if($before + $t[1] > 800 || $after + $t[1] > 800)
		{
			my @pos1=GetRegion(800, $readlen, $t[1], $t[5], $t[6]);
			print "$id\t$t[1]\t$depth{$id}\t$before\t$after\t$pos[0][0];$pos[1][0]\t$pos1[0][0];$pos1[1][0]\t$pos[2][0];$pos[3][0]\t$pos1[2][0];$pos1[3][0]\n";
		}else{
			print "$id\t$t[1]\t$depth{$id}\t$before\t$after\t$pos[0][0];$pos[1][0]\t$pos[2][0];$pos[3][0]\n";
		}
	}
}
close IN;

sub GetRegion{

	my ($insert, $readlen, $gaplen, $before, $after) =@_;
	#my $pos = shift;
	my @pos;
	my ($bs, $be, $as, $ae);
	my $len=150; #gaplen must > len.
	$bs = $insert - $readlen - $before;
	$be = $insert - $readlen;
	$as = $gaplen - $be;
	$ae = $gaplen - ($insert - $readlen - $after);
	
	if($bs < $len)
	{
		$bs = 0;
	}
	if($bs > $gaplen - $len)
	{
		$bs = $gaplen;
	}
	if($as < $len)
	{	$as = 0;}
	if($as > $gaplen - $len)
	{	$as = $gaplen;}
	#if($ae < $len)
	#{
	#	$ae = $gaplen;
	#}
	#if($ae > $gaplen - $len)
	#{
	#	$ae = 0;
	#}
	
	if($be > $gaplen - $len)
	{
		$be = $gaplen;
	}
	if($ae < $len)
	{
		$ae = 0;
	}
	if($ae > $gaplen - $len)
	{	$ae = $gaplen;}
	#if($as > $gaplen - $len)
	#{
	#	$as = 0;
	#}
	push @pos, [$bs];
	push @pos, [$be];
	push @pos, [$as];
	push @pos, [$ae];
	#print "$pos[0]\t$pos[3]\n";
	return @pos;
}

