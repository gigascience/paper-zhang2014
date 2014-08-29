#!/usr/bin/perl

#gap read stat analysis.

my $gr=shift;
my $readlen = 100;
my $large = 1500;
my $low = 10;

open WR, ">$gr.gapread.depth";
open WRR, ">$gr.ER.lst";

my $readnum=0;
my %start;
my %end;
my %len;
my %num;

open (IN,"gzip -dc $gr|")||die "fail open $gr\n";
while(<IN>)
{
	if(/>/)
	{
		$readnum=$readnum+1;
		my @t=split /\t/;
		my $id = $1 if($t[0]=~ />(\d+)/);
		$len{$id}=$t[1];
		$num{$id} = $num{$id} +1;
		$start{$id}=$len{$id} unless (exists $start{$id});
		$end{$id}=0 unless(exists $end{$id});
		if($t[2] < $start{$id})
		{
			$start{$id} = $t[2];
		}
		if($t[2] > $end{$id})
		{
			$end{$id}=$t[2];
		}
	}
}
close IN;
if($readnum == 0) {
    print "readstat.pl finish because of $gr has no read , please check whether the $gr generated correct !\n" ;
    print "you can check the krs or SR result !\n";
}
my $gapnum=0;
my $ernum=0;
my $largenum=0;
my $lowdepth=0;

foreach $k(sort keys %len)
{
	$gapnum=$gapnum+1;
	my $depth = $num{$k}*100/$len{$k};
	$depth = int($depth * 100)/100;
	if($depth <= $low)
	{
		$lowdepth=$lowdepth+1;
	}
	print WR "gap$k\t$len{$k}\t$depth\n";
	if($start{$k} >= 0 || $end{$k} <= $len{$k} - 200)
	{
		$ernum=$ernum+1;
		print WRR "gap$k\n";
	}
	if($len{$k} >= $large)
	{
		$largenum=$largenum+1;
	}
}
my $possiblefill=$gapnum - $ernum - $largenum -$lowdepth;
my $ratio = int($possiblefill/$gapnum*10000)/100;

print "read num;gap num;ER gap num;large gap num;low depth gap num;can fullfill num; can fullfill ratio\n";
print "$readnum;$gapnum;$ernum;$largenum;$lowdepth;$possiblefill;$ratio\n";
