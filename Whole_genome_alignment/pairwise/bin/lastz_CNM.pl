#!/usr/bin/perl
=head1 Description

 lastz, chain, net & maf pipeline;

=head1 Version

 Yongli Zeng, zengyongli@genomics.cn, 2011-07-11;
 BoLi, libo@genomics.cn, 2011-08-15, modified
 Version 0.91, 2011-08-15

=head1 Options

 --output <str>      output_dir for output files, default "./output";
 --cuts <int>        split the task into <int> files, default 20;

 --lastzStep <int>   parameters for lastz, default 19;
 --hspthresh <int>   parameters for lastz (K=), default 3000;
 --gappedthresh<int> parameters for lastz (L=), default 3000;
 --ydrop <int>       parameters for lastz (Y=), default 9400;
 --inner <int>       parameters for lastz (H=), default 0;
 --seed <str>        parameters for lastz 12of19 (T=1 or 2) or 14of22 (T=3 or 4), default 12of19;
 --scores <str>      parameters for lastz (--Q=): HOXD70, HoxD55, human-chimp.v2, default: HOXD70;
 --format <str>      parameters for lastz:lav, lav+text, axt, axt+, maf, maf+, maf-, sam, softsam, sam-, softsam-,                                           cigar, differences, rdotplot, text , default axt;
 --chain <str>       parameters for lastz (c=2 or 1): --chain or " ", default " "; 

 --minScore <int>    parameters for chain, default 5000;
 --linearGap <str>   parameters for chain: medium or loose, default medium;

 --tn <str>          name for target in maf, default as filename of target.fa;
 --qn <str>          name for query in maf, default as filename of query.fa;
 --step <str>        1:initial; 2:split; 3:lastz; 4:chain; 5:net; 6:maf; default: "123456";
 --run <str>         set the parallel type: qsub or multi, default=qsub;
 --cpu <num>         set the cpu number to use in parallel, default=5;
 --help              show this page;

=head1 Usage

 nohup perl lastz_CNM.pl target.fa query.fa &

=cut


use strict;
use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
use Cwd;

my ($output_dir,$cuts,$lastzStep,$hspthresh,$gappedthresh,$ydrop,$inner,$seed,$scores,$format,$chain,$minScore,$linearGap,$tn,$qn,$step,$run,$cpu,$help);
GetOptions(
	"ouput:s"	=> \$output_dir,
	"cuts:i"	=> \$cuts,
        "lastzStep:i"   => \$lastzStep,
	"hspthresh:i"   => \$hspthresh,
	"gappedthresh:i" => \$gappedthresh,
	"ydrop:i"       => \$ydrop,
        "inner:i"       => \$inner,
        "seed:s"        => \$seed,
        "scores:s"      => \$scores,
        "format:s"      => \$format,
        "chain:s"       => \$chain,
        "minScore:i"    => \$minScore,
        "linearGap:s"   => \$linearGap,
	"tn:s"	        => \$tn,
	"qn:s"		=> \$qn,
	"step:s"	=> \$step,
	"run:s"		=> \$run,
	"cpu:i"	        => \$cpu,
	"help"		=> \$help,
)or die "Unknown option!\n";

$output_dir ||= ".";
$cuts       ||= 20;
$lastzStep  ||= 19;
$hspthresh  ||= 3000;
$gappedthresh ||= 3000;
$ydrop      ||= 9400;
$inner      ||= 0;
$seed       ||= '12of19';
$scores     ||= "HOXD70";
$format     ||= "axt";
$chain      ||= " ";
$minScore   ||= 5000;
$linearGap  ||= "medium";
$tn         ||= "target";
$qn         ||= "query";
$step       ||= "123456";
$run        ||= "qsub";
$cpu        ||= 5;

die `pod2text $0` if (@ARGV != 2 || $help);

my $target =shift;
my $query =shift;

my $lastz_para = "--step=$lastzStep --hspthresh=$hspthresh --gappedthresh=$gappedthresh --ydrop=$ydrop --inner=$inner --seed=$seed --format=$format $chain --scores=$Bin/$scores ";
my $chain_para = "-minScore=$minScore -linearGap=$Bin/$linearGap";

my $name_t = basename($target);
my $name_q = basename($query);

# step1: initial
my $time = time();
if ($step =~ /1/)
{
	`$Bin/faToTwoBit $target $output_dir/$tn.2bit`;
	`$Bin/faToTwoBit $query $output_dir/$qn.2bit`;
	`$Bin/faSize $target -detailed > $output_dir/$tn.sizes`;
	`$Bin/faSize $query -detailed > $output_dir/$qn.sizes`;
	print STDERR "\nstep1: faToTwoBit and faSize, Finished.\n";
}

#step2: split
if ($step =~ /2/)
{
	testmkdir("$output_dir/1.query");
	`$Bin/split_fasta.pl $query  $output_dir/1.query $cuts avg yes`;
	print STDERR "\nstep2: split, finished.\n";
}

# step3: run lastz
if ($step =~ /3/){
	testmkdir("$output_dir/2.lastz");
	my $path =getcwd();
	my @files = <$output_dir/1.query/*.2bit>;
	my $sh;
	foreach my $fl(@files)
	{
		my $name = basename $fl;
		$name =~ s/\.2bit$//;
		$sh .= "$Bin/lastz $path/$output_dir/$tn.2bit[multi]  $path/$fl $lastz_para > $path/$output_dir/2.lastz/$name.axt\n";	
	}

	my $lastz_shell = "$output_dir/lastzshell.$$.sh";
	open SH, ">$lastz_shell" or die "can't open $lastz_shell\n";
	print SH $sh;
	close SH;

	`perl $Bin/qsub-sge.pl --convert no --maxjob $cpu  --resource vf=3G --reqsub $lastz_shell` if ($run eq "qsub");
	`perl $Bin/multi-process.pl -cpu $cpu $lastz_shell` if ($run eq "multi");
}

# step4: chain
if ($step =~ /4/)
{
	testmkdir("$output_dir/3.chain");
	my @chr_lastz = <$output_dir/2.lastz/*axt>;
	foreach (@chr_lastz)
	{
		my $name = basename($_);
		my $qname = $name;
		$qname =~ s/axt$/2bit/;
		`$Bin/axtChain $chain_para $output_dir/2.lastz/$name $output_dir/$tn.2bit  $output_dir/1.query/$qname $output_dir/3.chain/$name.chain`;
	}
}

# step5: net
if ($step =~ /5/)
{
	testmkdir("$output_dir/4.prenet");
	testmkdir("$output_dir/5.net");
	`$Bin/chainMergeSort $output_dir/3.chain/*.chain > $output_dir/4.prenet/all.chain`;
	`$Bin/chainPreNet $output_dir/4.prenet/all.chain $output_dir/$tn.sizes $output_dir/$qn.sizes $output_dir/4.prenet/all_sort.chain`;
	`$Bin/chainNet $output_dir/4.prenet/all_sort.chain $output_dir/$tn.sizes $output_dir/$qn.sizes $output_dir/5.net/temp.tn $output_dir/5.net/temp.qn`;
	`$Bin/netSyntenic $output_dir/5.net/temp.tn $output_dir/5.net/$tn.net`;
	`$Bin/netSyntenic $output_dir/5.net/temp.qn $output_dir/5.net/$qn.net`;
}

# step6: maf
if ($step =~ /6/)
{
	testmkdir("$output_dir/6.net_to_axt");
	testmkdir("$output_dir/7.maf");
	`$Bin/netToAxt $output_dir/5.net/$tn.net $output_dir/4.prenet/all_sort.chain $output_dir/$tn.2bit $output_dir/$qn.2bit $output_dir/6.net_to_axt/all.axt`;
	`$Bin/axtSort $output_dir/6.net_to_axt/all.axt $output_dir/6.net_to_axt/all_sort.axt`;
	`$Bin/axtToMaf -tPrefix=$tn -qPrefix=$qn $output_dir/6.net_to_axt/all_sort.axt $output_dir/$tn.sizes $output_dir/$qn.sizes $output_dir/7.maf/all.maf`;
}

$time = time() - $time;
my $hour = int($time / 3600);
my $minute = int(($time - $hour * 3600) / 60);
my $second = int($time % 60);
print "\nTotal time cost: $hour h $minute m $second s.\n";

#################
sub testmkdir(){
	my $dir = shift;
	if (-e $dir){
		warn "Warning: Folder ($dir) exists! all files in it will be deleted!\n";
		`rm -r $dir`;
	}
	`mkdir -p $dir`;
}

