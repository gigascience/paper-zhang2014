#!/usr/bin/perl

my $unfull=shift;
my $gapinfo=shift;
my $lengthcut=100;

my %list;
open IN,$unfull;
while(<IN>)
{
	if(/>(\w+)/)
	{
		$list{$1}=1;
	}
}
close IN;

my ($total,$filled,$unfill,$oneN,$middleshort,$middlelong,$oneNbothshort,$oneNeithershort,$oneNbothlong,$oneshort,$twoshort,$noshort,$nextoneN)=(0,0,0,0,0,0,0,0,0,0,0,0,0);
my $nowscaf=-1;

open IN,$gapinfo;
while(<IN>)
{
	chomp;
	my @t=split /\t/;
	$total=$total+1;
	#gap3    scaffold1       3       13      1183658 -       1       106     1057922 +       1       45
	if (exists $list{$t[0]})
	{
		$filled=$filled+1;
		if($t[3] eq 1)
		{
			$fillone=$fillone+1;
		}
		$beforeoneN=0;
		next;
	}
	print $_,"\n";
	$unfill=$unfill+1;

	if($t[7] < $lengthcut && $t[8] <$lengthcut)
	{
		$twoshort=$twoshort+1;
	}elsif($t[7] < $lengthcut || $t[8] <$lengthcut){
		$oneshort=$oneshort+1;
	}else{
		$noshort=$noshort+1;
	}
	if($t[1] ne $nowscaf)
	{
		$nowscaf=$t[1];
		$beforeoneN=0;
	}
	if($t[3] ne 1)
	{
		$beforeoneN=0;
	}else{
		$oneN = $oneN+1;
		if($beforeoneN eq 1)
		{
			$nextoneN = $nextoneN + 1;
			if($t[7] < $lengthcut)
			{
				$middleshort=$middleshort+1;
			}
			if($t[7] > 1000)
			{
				$middlelong=$middlelong+1;
			}
		}
		$beforeoneN = 1;
		if($t[7] < $lengthcut && $t[8] <$lengthcut)
		{
			$oneNbothshort=$oneNbothshort+1;
		}elsif($t[7] < $lengthcut || $t[8] <$lengthcut){
			$oneNeithershort=$oneNeithershort+1;
		}else{
			$oneNbothlong = $oneNbothlong +1;
		}
	}
}
close IN;
print STDERR "total_gap_num\tfill_gap_num\tunfull_gap_num\tfill_oneN_num\tunfill_both_short\tunfill_one_short\tunfill_no_short\tunfill_oneN_num\tunfill_oneN_bothshort\tunfill_oneN_oneshort\tunfill_oneNlong\tnext_oneN\toneN_middleshort\toneN_middlelong\n";
print STDERR "$total\t$filled\t$unfill\t$fillone\t$twoshort\t$oneshort\t$noshort\t$oneN\t$oneNbothshort\t$oneNeithershort\t$oneNbothlong\t$nextoneN\t$middleshort\t$middlelong\n";
