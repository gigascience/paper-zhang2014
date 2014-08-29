#!/user/bin/perl

my $kgf=shift;
my $dir=shift;
my $num=shift;
my $thread=shift;

for(my $i=1; $i<=$num; $i=$i+1)
{
	print "$kgf -g $dir/F$i/gapread.fa -c $dir/F$i/contig.fa -o $dir/F$i -m 5 -t $thread >$dir/F$i/gapSeq.fa 2>$dir/F$i/kgf.log;\n";
}
