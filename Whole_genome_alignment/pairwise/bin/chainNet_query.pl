#!/usr/bin/perl

#2011.10.18

if (@ARGV != 1)
{
	print "perl $0 <dir: ./>\n";
	exit;
}

use strict;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
use Cwd;

my  $output_dir = shift;


my $tn = "target";
my $qn = "query";


# step4: chainSwap
testmkdir("$output_dir/3.query.chain");
my @chr_chain = <$output_dir/3.chain/*chain>;
foreach (@chr_chain)
{
	my $name = basename($_);
	system "$Bin/chainSwap $_ $output_dir/3.query.chain/$name";	
}

# step5: net
`$Bin/chainMergeSort $output_dir/3.query.chain/*.chain > $output_dir/4.prenet/query.all.chain`;
`$Bin/chainPreNet $output_dir/4.prenet/query.all.chain $output_dir/$qn.sizes $output_dir/$tn.sizes $output_dir/4.prenet/query.all_sort.chain`;
`$Bin/chainNet $output_dir/4.prenet/query.all_sort.chain $output_dir/$qn.sizes $output_dir/$tn.sizes $output_dir/5.net/query.temp.1 $output_dir/5.net/query.temp.2`;
`$Bin/netSyntenic $output_dir/5.net/query.temp.1 $output_dir/5.net/query.temp.1.net`;


# step6: maf
`$Bin/netToAxt $output_dir/5.net/query.temp.1.net $output_dir/4.prenet/query.all_sort.chain $output_dir/$qn.2bit  $output_dir/$tn.2bit $output_dir/6.net_to_axt/query.net.axt`;
`$Bin/axtSort $output_dir/6.net_to_axt/query.net.axt $output_dir/6.net_to_axt/query.net.sort.axt`;
`$Bin/axtToMaf -tPrefix=query -qPrefix=target $output_dir/6.net_to_axt/query.net.sort.axt $output_dir/$qn.sizes  $output_dir/$tn.sizes $output_dir/7.maf/query.all.maf`;



#################
sub testmkdir()
{
	my $dir = shift;
	if (-e $dir){
		warn "Warning: Folder ($dir) exists! all files in it will be deleted!\n";
		`rm -r $dir`;
	}
	`mkdir -p $dir`;
}

