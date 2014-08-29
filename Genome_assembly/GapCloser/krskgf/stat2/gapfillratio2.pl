#!/user/bin/perl

my $dir=shift;
my $thread=shift;

my ($totalgapnum, $totalgaplen, $noreadgapnum, $fillgapnum, $fillgaplen, $fullfillnum);

for(my $i=1; $i<=$thread; $i=$i+1)
{
	my $file="$dir/F$i/kgf.log";
	my $check = `tail -n 6 $file |head -n 1`;
	if($check ne "All the scaffold gaps treat finished!\n")
	{
		print "Error: please check work in F$i!$check.\n";
	}

	my $line=`tail -n 3 $file |head -n 1`;
	my ($totalgapnum0, $totalgaplen0, $noreadgapnum0, $fillgapnum0, $fillratio, $fillgaplen0, $fullfillnum0, $fullfillratio, $unfill)=split /\t/, $line; 
	$totalgapnum= $totalgapnum + $totalgapnum0;
	$totalgaplen =$totalgaplen+ $totalgaplen0;
	$noreadgapnum =$noreadgapnum+$noreadgapnum0;
	$fillgapnum=$fillgapnum+$fillgapnum0;
	$fillgaplen =$fillgaplen+$fillgaplen0;
	$fullfillnum =$fullfillnum+$fullfillnum0;
}
my $fillratio=int($fillgapnum/$totalgapnum*10000)/100;
my $fullfillratio = int($fullfillnum/$fillgapnum*10000)/100;
my $unfullfillnum = $totalgapnum - $fullfillnum;

print "Totalgapnum\tTotalgaplen\tNoreadgap\tFillgapnum\tFillgapratio\tFillgaplen\tFullfillnum\tFullfillratio\tunfullfillnum\n";
print "$totalgapnum\t$totalgaplen\t$noreadgapnum\t$fillgapnum\t$fillratio\t$fillgaplen\t$fullfillnum\t$fullfillratio\t$unfullfillnum\n";
