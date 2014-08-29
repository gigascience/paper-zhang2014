#!/user/bin/perl

my $gapread=shift;
my $contig=shift;

my $cpu=shift;
my $scafnum=shift;

my $outdir=shift;

if($cpu eq 0)
{
	print "Please check $cpu\n";
	exit(-1);
}
my $numcut=int($scafnum/$cpu) + 1;

my $dir = "$outdir/F1";
mkdir $dir unless (-d $dir);
open WR,">$dir/contig.fa";

my $num=0;
my $filenum=1;
my ($nowid,$id);
open IN,$contig;
while(<IN>)
{
	if(/caffold(\d+)/)
	{
		$id=$1;
		if($id ne $nowid)
		{
			$num=$num+1;
			$nowid =$id;
			if($num eq $numcut)
	                {
        	                close WR;
                	        $filenum=$filenum+1;
                        	my $dir = "$outdir/F$filenum";
	                        mkdir $dir unless (-d $dir);
        	                open WR,">$dir/contig.fa";
                	        $num=0;
			}
		}
		$keep{$id}=$filenum;
		print WR $_;
		my $seq = <IN>;
		print WR $seq;
	}
}
close IN;
close WR;

for(my $i=1; $i<=$filenum; $i=$i+1)
{
	my $dir="$outdir/F$i";
	open ($i,">$dir/gapread.fa");
}

open IN,$gapread;
while(<IN>)
{
	if(/>/)
	{
		my @t=split /\t/;
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
print $filenum;
