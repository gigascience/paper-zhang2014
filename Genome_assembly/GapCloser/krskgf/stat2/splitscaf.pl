#!/user/bin/perl


my $fa=shift;
open WR,">$fa.SCAF";
open WRR,">$fa.CONTIG";
my $len=0;
my $num=0;
open FA,$fa or die "$!";
$/=">";<FA>;$/="\n";
while(<FA>)
{
                my $head=$_;
#                my $name=$1 if(/(\S+)/);
                $/=">";
                my $seq=<FA>;
                chomp $seq; #delete >
		#$len = $len + length($seq);
                $/="\n";
#               my @s=split (/\n/,$seq);
#               my $sequ;
#               for(my $i=0; $i<@s; $i=$i+1)
#               {
#                       $sequ="$s[$i].$sequ";
#               }
                #print length($seq),"\t";
                $seq=~s/\W+//g;
                #print length($seq),"\n";
#                $sequence{$name}=$seq;

	if($seq=~/N/){
		print WR ">$head$seq\n";
		$len = $len + length($seq);
		$num=$num+1;
	}else{
		print WRR ">$head$seq\n";
	}
}
close FA;
close WR;
close WRR;
print "$num\t$len";
