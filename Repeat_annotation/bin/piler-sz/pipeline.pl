#!/usr/bin/perl
use strict;
use FindBin qw($Bin $Script);
use lib "$Bin/../../bin/Annotation_pipeline1_1.0/common_bin";
use GACP qw(parse_config);

my $config_file="$Bin/../../bin/Annotation_pipeline1_1.0/config.txt";
my $pals=parse_config($config_file,"pals_path");
my $dir=shift;
opendir THIS,$dir or die "$!";
my @fa=grep {/\d+$/}readdir THIS;
close THIS;
open OUT,">find_pals.sh";
foreach my $i(0..@fa-1)
{
		my $filename=$dir.$fa[$i];
		print OUT "$pals -self $filename -out $fa[$i].hit.gff  >>pals$i.log  2>>pals$i.log2;  echo $fa[$i].hit.gff;\n";

		for (my $j=$i+1;$j<@fa;$j++)
		{
				my $file=$dir.$fa[$j];
				print OUT "$pals    -target $filename -query $file -out $fa[$i].$fa[$j].hit.gff >>pals$i$j.log 2>>pals$i$j.log2;  echo  $fa[$i].$fa[$j].hit.gff;\n";
}

}

close OUT;
