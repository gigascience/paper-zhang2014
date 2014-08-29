#!/user/bin/perl

my $gapread=shift;
my $contig=shift;

my $cpu=shift;
#my $scafnum=shift;

my $outdir=shift;

if($cpu eq 0)
{
	print "Please check $cpu\n";
	exit(-1);
}
#my $numcut=int($scafnum/$cpu) + 1;

for(my $i=1; $i<=$cpu; $i=$i+1)
{
	my $dir = "$outdir/F$i";
	if(-d $dir)
	{
		`rm -rf $dir`;
	}
	mkdir $dir;# unless(-d $dir);
	open ($i,">$dir/contig.fa");
}

my ($nowid,$id, $nownum);
my $num=0;
my %keep;
open (IN,$contig) || die "fail open $contig in Cut2.pl !\n";
while(<IN>)
{
	if(/caffold(\d+)/)
	{
		$id=$1;
		
		if($id ne $nowid)
		{
			$num=$num+1;
			$nowid =$id;
			if($num == $cpu + 1)
			{$num=1;}
			$nownum = $num % ($cpu + 1);
		}
		$keep{$id}=$nownum;
		print ($nownum $_);
		my $seq = <IN>;
		print ($nownum $seq);
	}
}
close IN;

for(my $i=1; $i<=$cpu; $i=$i+1)
{
	close $i;
}
for(my $i=1; $i<=$cpu; $i=$i+1)
{
	my $dir="$outdir/F$i";
	open ($i,">$dir/gapread.fa");
}

open (IN,$gapread) || die "fail open $gapread in Cut2.pl !\n";
while(<IN>)
{
	if(/>/)
	{
		my @t=split /\t/;
		unless (exists $keep{$t[3]})
		{
			print "Error: $t[3]\t$keep{$t[3]}. Please check scaffold id in gapread and contig seq.\n";
			exit(0);
		}
		$nownum=$keep{$t[3]};
		print ($nownum $_);
		my $seq = <IN>;
		print ($nownum $seq);
	}
}
close IN;

for(my $i=1; $i<=$filenum; $i=$i+1)
{
        close $i;
}

