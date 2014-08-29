#!/user/bin/perl
use strict;

my $cover=shift;
my $tr=shift;
my $depth =shift;
my $er=shift;

my %h;
open WR, ">canfullfill.lst";
my $ernum=0;

open IN,$er;
while(<IN>)
{
	#chomp;
	#$ernum=$ernum+1;
	#$h{$_}=1;
	if(/gap(\d+)/)
        {
                $ernum=$ernum+1;
                $h{"gap$1"}=1;
        }
}
close IN;

my $trnum=0;
open IN,$tr;
while(<IN>)
{
	if(/gap(\d+)/)
	{
		$trnum=$trnum+1;
		$h{"gap$1"}=1;
	}
}
close IN;

my $uncovernum=0;
open IN,$cover;
while(<IN>)
{
	chomp;
	my @t=split /\t/;
	my $key;
	if($t[0]=~ />(\S+)/)
	{
		$key =$1;
	}else{
		$key =$t[0];
	}
	#print $t[2],"\n";
	if($t[3] < 1)
	{
		$h{$key}=1;
		$uncovernum=$uncovernum+1;
	}
}
close IN;

my $largenum=0;
my $low=0;
my $total=0;

open IN,$depth;
while(<IN>)
{
	chomp;
	$total=$total+1;
	my @t=split /\t/;
	if($t[1] >= 1500)
	{
		$largenum=$largenum+1;
		$h{$t[0]}=1;
	}
	if($t[2] <= 10)
	{
		$low=$low+1;
		$h{$t[0]}=1;
	}
	next if(exists $h{$t[0]});
	print WR "$_\n";
}
close IN;
close WR;
my $unfullnum =0;
foreach my $k(keys %h)
{
	$unfullnum=$unfullnum+1;
}
my $fullnum = $total - $unfullnum;
my $fullratio = int($fullnum/$total *10000)/100;

print "total gap num;large gap num;low depth gap num; TR gap num; ER gap num; uncover num;can fullfill num; can fullfill ratio\n";
print "$total;$largenum;$low;$trnum;$ernum;$uncovernum;$fullnum;$fullratio\n";

