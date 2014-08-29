#!/user/bin/perl
use strict;
my $file=shift;

open IN,$file;
while(<IN>)
{
	#443     397     100     149     397;397 0;0
	chomp;
	my @t=split /\t/;
	my @pos;
	my $len = $t[1];
	my $cover=0;
	my @region;
	for(my $i=@t-1; $i >=5; $i=$i-1)
	{
		my @m=split (/;/, $t[$i]);
		if(@m eq 1)
		{last;}
		if($m[0] eq $m[1])
		{next;}
		if($m[1] - $m[0] eq $len)
		{
			$cover=1;
			last;
		}
		if(@region >= 1)
		{
			my $push =0;
			for(my $j=0; $j < @region; $j=$j+1)
			{
				if($m[0] < $region[$j][0])
				{
					if($m[1] < $region[$j][0])
					{
						$push=1;			
					}else{
						$region[$j][0] = $m[0];
						$push=0;
						if($m[1] > $region[$j][1])
						{	$region[$j][1] = $m[1];}
						last;
					}
				}elsif($m[1] > $region[$j][1])
				{
					if($m[0] > $region[$j][1])
					{
						$push =1;
					}else{
						$region[$j][1] = $m[1];
						$push=0;
						last;
					}
				}else{
					$push =0;
					last;
				}
			}
			if($push eq 1)
			{
				push @region, [$m[0], $m[1]];
			}
		}else{
			push @region, [$m[0], $m[1]];
		}
	}
	if(@region >= 1 && $cover ne 1)
	{
		for(my $j=0; $j < @region; $j=$j+1)
		{
			#print "line: $region[$j][0]\t$region[$j][1]\n";
			$cover = $cover + $region[$j][1] - $region[$j][0];
		}
	}
	if($cover ne 1)
	{$cover = $cover /$len;}
	print "$t[0]\t$len\t$t[2]\t$cover\n";
}
close IN;
