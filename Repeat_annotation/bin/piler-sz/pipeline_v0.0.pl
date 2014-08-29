#!/usr/bin/perl
use strict;
my $dir=shift;
opendir THIS,$dir or die "$!";
my @fa=grep {/\d+$/}readdir THIS;
close THIS;
open OUT,">find_pals.sh";
foreach my $i(0..@fa-1)
{
		my $filename=$dir.$fa[$i];
		print OUT "/ifs2/BC_GAG/Bin/Annotation/software/piler-sz/pals/pals -self $filename -out $fa[$i].hit.gff  >>pals$i.log  2>>pals$i.log2;  echo $fa[$i].hit.gff;\n";

		for (my $j=$i+1;$j<@fa;$j++)
		{
				my $file=$dir.$fa[$j];
				print OUT "/ifs2/BC_GAG/Bin/Annotation/software/piler-sz/pals/pals    -target $filename -query $file -out $fa[$i].$fa[$j].hit.gff >>pals$i$j.log 2>>pals$i$j.log2;  echo  $fa[$i].$fa[$j].hit.gff;\n";
}

}

close OUT;
