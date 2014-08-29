#!/usr/bin/perl
=head1 Description

 lastz, chain, net & maf pipeline;

=head1 Version

 Yongli Zeng, zengyongli@genomics.cn
 Version 0.9, 2011-07-11

=head1 Options

 --direction <str>    direction for output files,
                        default "./output";
 --mode <str>         mode selection, "multi" or "single",
                        default "multi";
 --num <int>          split the task into <int> files,
                        default 20;
 --parasuit <str>     easily set parameters suit to define --lpara and --apara.
                        "chimp": for human vs chimp, gorilla, rhesus, marmoset and so on; (near)
                        "chick": for human vs chicken, zebra finch and so on; (far)
                        *** chimp ********************************************************************************
                        * --lpara:
                        *   --hspthresh=4500 --gap=600,150 --ydrop=15000 --notransition
                        *   --scores=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/chimpMatrix --format=axt
                        * --apara:
                        *   -minScore=5000 -linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/medium
                        ******************************************************************************************

                        *** chick ********************************************************************************
                        * --lpara:
                        *   --step=19 --hspthresh=2200 --inner=2000 --ydrop=3400 --gappedthresh=10000
                        *   --scores=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/birdMatrix --format=axt
                        * --apara:
                        *   -minScore=5000 -linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/loose
                        ******************************************************************************************
 --lpara <str>        parameters for lastz,
                        default "--format=axt";
 --apara <str>        parameters for axtChain,
                        default "-linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/medium";
 --tn <str>           name for target in maf,
                        default as filename of target.fa;
 --qn <str>           name for query in maf,
                        default as filename of query.fa;
 --step <str>         1:initial; 2:split; 3:lastz; 4:chain; 5:net; 6:maf;
                        default: "123456";
 --qsub               use qsub-sge.pl to run lastz & chain;

 --qpara <str>        parameters for qsub-sge.pl,
                        default "--maxjob 50 --resource vf=1.5g --reqsub --convert no";
 --help               show this page;

=head1 Usage

 nohup perl lacnem.pl target.fa query.fa &

=cut


use strict;
use FindBin qw($RealBin);
use File::Basename;
use Getopt::Long;
use Cwd;

my $pathway = $RealBin;
$pathway =~ s/[\w\.]+\/\w+$/lastz/;

my ($direction, $mode, $num, $parasuit, $lpara, $apara, $tn, $qn, $step, $qsub, $qpara, $help);
GetOptions(
	"direction:s"	=> \$direction,
	"mode:s"		=> \$mode,
	"num:i"			=> \$num,
	"parasuit:s"    => \$parasuit,
	"lpara:s"    	=> \$lpara,
	"apara:s"       => \$apara,
	"tn:s"			=> \$tn,
	"qn:s"			=> \$qn,
	"step:s"		=> \$step,
	"qsub"			=> \$qsub,
	"qpara:s"	    => \$qpara,
	"help"			=> \$help,
)or die "Unknown option!\n";

my $fasta_target =shift;
my $fasta_query =shift;

die `pod2text $0` if (!($fasta_target && $fasta_query) || $help);
die "$fasta_target not found!\n" unless (-e $fasta_target);
die "$fasta_query not found!\n" unless (-e $fasta_query);

$direction ||= "./output";
$direction =~ s/\/$//;
$mode ||= "multi";
$num ||= 20;
if ($parasuit eq "chimp"){
	$lpara = "--hspthresh=4500 --gap=600,150 --ydrop=15000 --notransition --scores=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/chimpMatrix --format=axt";
	$apara = "-minScore=5000 -linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/medium";
}elsif ($parasuit eq "chick"){
	$lpara = "--step=19 --hspthresh=2200 --inner=2000 --ydrop=3400 --gappedthresh=10000 --scores=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/birdMatrix --format=axt";
	$apara = "-minScore=5000 -linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/loose";
}elsif ($parasuit ne ""){
	die "error --parasuit option value: $parasuit\n";
}
$lpara ||= "--format=axt";
$apara ||= "-linearGap=/panfs/ANIMAL/GROUP/group003/zengyl/0.software/lastz/medium";
my $n1 = basename($fasta_target);
my $n2 = basename($fasta_query);
$n1 =~ s/\..*$//;
$n2 =~ s/\..*$//;
$tn ||= $n1;
$qn ||= $n2;
$step ||= "123456";
$qpara ||= "--maxjob 50 --resource vf=1.5g --reqsub --convert no";
$tn .= ".";
$qn .= ".";

#die "$qsub_para\n";
# step1: initial
my $time = time();
if ($step =~ /1/){
	testmkdir("$direction/1.target");

	`$pathway/faToTwoBit $fasta_target $direction/target.2bit`;
	`$pathway/faToTwoBit $fasta_query $direction/query.2bit`;

	`$pathway/faSize $fasta_target -detailed > $direction/target.sizes`;
	`$pathway/faSize $fasta_query -detailed > $direction/query.sizes`;
	
}

#step2: split
if ($step =~ /2/){
	if ($mode eq "single"){
		`$RealBin/split_fasta.pl $fasta_target $direction/1.target 999999999 avg yes`;
	}else{
		`$RealBin/split_fasta.pl $fasta_target $direction/1.target $num avg yes`;
	}
}

# step3: run lastz
if ($step =~ /3/){
	testmkdir("$direction/2.lastz");
	testmkdir("$direction/3.chain");
	my $path =getcwd();
	if ($direction =~ /^\//){
		$path = "";
	}
	$path .= "/";

	if ($qsub){
		open SH, ">$direction/lastzshell.sh" or die "can't open lastzshell.sh\n";
	}

	my @tdir = `ls $direction/1.target/*.2bit`;

	my $du = 0;
	foreach my $tt(@tdir){
		my $fa = $tt;
		chomp($fa);
		$fa =~ s/2bit$/fasta/;
		my $size = -s "$fa";
		$du += $size;
	}
	my $seg = int($du / $num);
	my $count = 0;
	my $i = 1;

	foreach my $tt(@tdir){
		chomp($tt);
		my $tinput = $path . "$tt";
		my $tinput_raw = $tinput;
		if ($mode eq "multi"){
			my $fa = $tt;
			chomp($fa);
			$fa =~ s/2bit$/fasta/;
			my $faline = `grep -c ">" $fa`;
			chomp($faline);
			$tinput .= "[multi]" if ($faline != 1);
		}
		my $qinput = $path . "$direction/query.2bit";
		my $nameaxt = basename($tt);
		$nameaxt =~ s/2bit$/axt/;
		$nameaxt = $path . "$direction/2.lastz/$nameaxt";
		my $namechain = basename($nameaxt);
		$namechain =~ s/axt$/chain/;
		$namechain = $path. "$direction/3.chain/$namechain";
		if ($qsub){
			if ($mode eq "multi"){
				print SH "$pathway/lastz $tinput $qinput $lpara > $nameaxt;\n";
				#print SH "$pathway/axtChain -linearGap=$pathway/medium $nameaxt $tinput_raw $qinput $namechain\n";
			}else{
				my $fa = $tt;
				$fa =~ s/2bit$/fasta/;
				my $size = -s "$fa";
				print SH "$pathway/lastz $tinput $qinput $lpara > $nameaxt; ";
				#print SH "$pathway/axtChain -linearGap=$pathway/medium $nameaxt $tinput_raw $qinput $namechain; ";
				$count += $size;
				if ($count >= $seg || $count / $seg > 0.95){
					print SH "\n";
					$i++;
					$count = 0;
				}
			}
		}else{
			#warn "lastz!\n";
			`$pathway/lastz $tinput $qinput $lpara > $nameaxt`;
			#`$pathway/axtChain -linearGap=$pathway/medium $nameaxt $tinput_raw $qinput $namechain`;
		}
	}
	if ($qsub){
		close SH;
		#die "over!\n";
		`/share/raid1/self-software/bin/qsub-sge.pl $direction/lastzshell.sh $qpara`;
	}
}

# step4: chain
if ($step =~ /4/){
	testmkdir("$direction/3.chain");
	my @chr_lastz = `ls $direction/2.lastz`;
	foreach (@chr_lastz){
		chomp;
		my $name = basename($_);
		my $tname = $name;
		$tname =~ s/axt$/2bit/;
		`$pathway/axtChain $apara $direction/2.lastz/$_ $direction/1.target/$tname $direction/query.2bit $direction/3.chain/$name.chain`;
	}
}

# step5: net
if ($step =~ /5/){
	testmkdir("$direction/4.prenet");
	testmkdir("$direction/5.net");
	`$pathway/chainMergeSort $direction/3.chain/*.chain > $direction/4.prenet/all.chain`;
	`$pathway/chainPreNet $direction/4.prenet/all.chain $direction/target.sizes $direction/query.sizes $direction/4.prenet/all_sort.chain`;
	`$pathway/chainNet $direction/4.prenet/all_sort.chain $direction/target.sizes $direction/query.sizes $direction/5.net/temp $direction/5.net/query.net`;
	`$pathway/netSyntenic $direction/5.net/temp $direction/5.net/target.net`;
}

# step6: maf
if ($step =~ /6/){
	testmkdir("$direction/6.net_to_axt");
	testmkdir("$direction/7.maf");
	`$pathway/netToAxt $direction/5.net/target.net $direction/4.prenet/all_sort.chain $direction/target.2bit $direction/query.2bit $direction/6.net_to_axt/all.axt`;
	`$pathway/axtSort $direction/6.net_to_axt/all.axt $direction/6.net_to_axt/all_sort.axt`;
	`$pathway/axtToMaf -tPrefix=$tn -qPrefix=$qn $direction/6.net_to_axt/all_sort.axt $direction/target.sizes $direction/query.sizes $direction/7.maf/all.maf`;
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

