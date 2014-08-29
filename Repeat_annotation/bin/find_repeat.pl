#!/usr/bin/perl

=head1 Name

	find_repeat.pl -- the pipeline of finding tandem repeats and transposons in sequences.

=head1 Description

	This program invoke trf, RepeatMasker, and RepeatProteinMask. The path of the softwares invoked will be put
	in the "config.txt".The first line of output files in gff3 format is "##gff-version 3".  

	For RepeatMasker, you can either use inside TE libary by -species option, or give self made TE libary
	by -lib option. But these two options can't be given at the same time.

=head1 Version

	Author: sunjuan		(sunjuan@genomics.org.cn)
	Mender: huangqf 	(huangqf@genomics.org.cn)
	Mender: fanw    	(fanw@genomics.org.cn)
	Mender: zhouheling      (zhouheling@genomics.org.cn)
	Version: 4.0	Date: 2010-05-18
	
=head1 Usage

	perl find-repeat.pl [options] input_file
	-trf             run trf
	-period_size <int>    set the maximum period size for trf, default=2000
	-repeatmasker    run RepeatMasker
	-lib <file>      set the lib file for RepeatMasker, default Repbase
	-sensitive       set the "-s" option for RepeatMasker
	-proteinmask     run RepeatProteinMask   
	-pvalue <str>    set the pvalue for RepeatProteinMask, default=1e-4
	-prefix <str>    set a prefix name for the gene ID in gff3
	-cutf <int>      set the number of cutted files
	-cpu <int>       set the cpu number to use in parallel, default=3
	-node <str>      set the compute node, eg h=compute-0-151,default is not set
	-queue <str>     set the queue to use, default no
	-pro_code <str>  set the code for project,default no
	-run <str>       set the parallel type, qsub or multi, default=qsub
	-outdir <str>    set the output directory
	-resource <str> set the required resource used in qsub -l option, default vf=3G
	-verbose         output verbose information to screen
	-help            output help information to screen.

=head1 Exmple

	perl bin/find_repeat.pl -trf -repeatmasker -proteinmask ../input/rice.frag1M.fa &

=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname); 
use Data::Dumper;
use lib "$Bin/lib";
use GACP qw(parse_config);

##get options from command line into variables and set default values
my ($Cutf,$Cpu,$Node,$Run,$Outdir,$Prefix,$RepeatMasker,$Lib,$Trf,$Period_size,$Proteinmask,$Pvalue,$Sensitive);
my ($Resource,$Verbose,$Help,$Queue,$Pro_code);
GetOptions(
	"prefix:s"=>\$Prefix,
	"cutf:i"=>\$Cutf,
	"cpu:i"=>\$Cpu,
	"node:s"=>\$Node,
	"run:s"=>\$Run,
	"trf"=>\$Trf,
	"period_size:s"=>\$Period_size,
	"repeatmasker"=>\$RepeatMasker,
	"lib:s"=>\$Lib,
	"sensitive"=>\$Sensitive,
	"proteinmask"=>\$Proteinmask,
	"pvalue:s"=>\$Pvalue,
	"outdir:s"=>\$Outdir,
	"resource:s"=>\$Resource,
	"queue:s"=>\$Queue,
	"pro_code:s"=>\$Pro_code,
	"verbose"=>\$Verbose,
	"help"=>\$Help
);
$Cutf ||= 1;
$Cpu ||= 3;
$Run ||= "qsub";
my $Dir = `pwd`; 
chomp ($Dir);
$Outdir ||= $Dir;
$Period_size ||= 2000;
my $repeatmasker_style;
my $config_file = "$Bin/../config.txt";
$Lib ||= parse_config($config_file,"tedna");
if ($Lib =~ /RepBase.*RepeatMasker/) {
	$repeatmasker_style="known";
} else {
	$repeatmasker_style="denovo";
}
$Pvalue ||= 1e-4;
$Resource ||= "vf=3G";
$Prefix = "--prefix $Prefix" if(defined $Prefix);
die `pod2text $0` if (@ARGV == 0 || $Help);

my $seq_file = shift;
my $seq_file_name = basename($seq_file);
my $species_name=$1 if ($seq_file_name=~/^(\w+)\./);

$Outdir =~ s/\/$//;
mkdir ($Outdir) unless(-d $Outdir);

my $repeatmasker = parse_config($config_file,"repeatmasker");
my $proteinmask = parse_config($config_file,"proteinmask");
my $trf = parse_config($config_file,"trf");
my $fastaDeal = parse_config($config_file,"fastaDeal.pl");
my $qsub_sge = parse_config($config_file,"qsub_sge.pl");
my $multi_process = parse_config($config_file,"multi-process.pl");

my $repeatmasker_para = "-nolow -no_is -norna -parallel 1 -lib $Lib ";
#my $repeatmasker_para = "-nolow -no_is -norna -engine wublast -parallel 1  ";
#   $repeatmasker_para .= "-lib $Lib " if (defined $Lib);
   $repeatmasker_para .= "-s " if($Sensitive);
my $proteinmask_para = "-noLowSimple -pvalue $Pvalue ";
my $trf_para = "2 7 7 80 10 50 $Period_size -d -h ";

my $repeatmasker_shell_file = "./$seq_file_name.RepeatMasker.$$.shell";
my $trf_shell_file = "./$seq_file_name.trf.$$.shell";
my $proteinmask_shell_file = "./$seq_file_name.proteinmask.$$.shell";

my @subfiles;

##add by luchx
my $QP_para;
$QP_para.="--queue $Queue " if (defined $Queue);
$QP_para.="--pro_code $Pro_code " if (defined $Pro_code);

##cut the input sequence file into small files
`$fastaDeal -cutf $Cutf $seq_file -outdir $Outdir`;
@subfiles = glob("$Outdir/$seq_file_name.cut/*.*");

## creat trf shell file and run the shell
if (defined $Trf) {
	open OUT,">$trf_shell_file" || die "fail $trf_shell_file";
	foreach my $subfile (@subfiles) {
		print OUT "$trf $subfile $trf_para\n";
	}
	close OUT;
	if(defined $Node){
		`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource --node $Node $trf_shell_file; mv $trf_shell_file.*.qsub/*.dat $Outdir/$seq_file_name.cut/;` if ($Run eq "qsub");
	}
	else{`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource  $trf_shell_file; mv $trf_shell_file.*.qsub/*.dat $Outdir/$seq_file_name.cut/;` if ($Run eq "qsub");}
	`$multi_process -cpu $Cpu $trf_shell_file; mv $Outdir/*.dat $Outdir/$seq_file_name.cut/;` if ($Run eq "multi");
	`cat $Outdir/$seq_file_name.cut/*.dat > $Outdir/$species_name.TRF.dat`;
	`perl $Bin/repeat_to_gff.pl $Prefix $Outdir/$species_name.TRF.dat`;
	`mv $Outdir/$species_name.TRF.dat.gff $Outdir/$species_name.TRF.gff`;
	## add stat TRF

}


## creat RepeatMasker shell file and run the shell
if (defined $RepeatMasker) {
	open OUT,">$repeatmasker_shell_file" || die "fail $repeatmasker_shell_file";
	foreach my $subfile (@subfiles) 
	{
		print OUT "$repeatmasker $repeatmasker_para  $subfile > $subfile.log 2> $subfile.log2\n";
	}
	close OUT;
	if(defined $Node){
		`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource --node $Node $repeatmasker_shell_file` if ($Run eq "qsub");
	}
	else{`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource  $repeatmasker_shell_file` if ($Run eq "qsub");}
	`$multi_process -cpu $Cpu $repeatmasker_shell_file` if ($Run eq "multi");
	`cat $Outdir/$seq_file_name.cut/*.out > $Outdir/$species_name.$repeatmasker_style.RepeatMasker.out`;
	`perl $Bin/repeat_to_gff.pl $Prefix $Outdir/$species_name.$repeatmasker_style.RepeatMasker.out`;
	`mv $Outdir/$species_name.$repeatmasker_style.RepeatMasker.out.gff $Outdir/$species_name.$repeatmasker_style.RepeatMasker.gff`;
	#`perl $Bin/stat_TE.pl --repeat $Outdir/$seq_file_name.RepeatMasker.out --rank all > $Outdir/$seq_file_name.RepeatMasker.out.stat.all`;
	#`perl $Bin/stat_TE.pl --repeat $Outdir/$seq_file_name.RepeatMasker.out --rank type > $Outdir/$seq_file_name.RepeatMasker.out.stat.type`;
	#`perl $Bin/stat_TE.pl --repeat $Outdir/$seq_file_name.RepeatMasker.out --rank subtype > $Outdir/$seq_file_name.RepeatMasker.out.stat.subtype`;
	#`perl $Bin/stat_TE.pl --repeat $Outdir/$seq_file_name.RepeatMasker.out --rank family > $Outdir/$seq_file_name.RepeatMasker.out.stat.family`;
}

## creat Proteinmask shell file and run the shell
if (defined $Proteinmask) {
	open OUT,">$proteinmask_shell_file" || die "fail $proteinmask_shell_file";
	foreach my $subfile (@subfiles) {
		print OUT "$proteinmask $proteinmask_para $subfile; \n";
	}

	close OUT;
	if(defined $Node){
		`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource --node $Node $proteinmask_shell_file` if ($Run eq "qsub");
	}
	else{`$qsub_sge $QP_para --maxjob $Cpu --reqsub --resource $Resource  $proteinmask_shell_file` if ($Run eq "qsub");}
	`$multi_process -cpu $Cpu $proteinmask_shell_file` if ($Run eq "multi");
	`cat $Outdir/$seq_file_name.cut/*.annot > $Outdir/$species_name.RepeatProteinMask.annot`;
	`perl $Bin/repeat_to_gff.pl $Prefix $Outdir/$species_name.RepeatProteinMask.annot`;
	`mv $Outdir/$species_name.RepeatProteinMask.annot.gff $Outdir/$species_name.RepeatProteinMask.gff`;
	#`perl $Bin/stat_TE.pl --protein $Outdir/$seq_file_name.Proteinmask.annot --rank all > $Outdir/$seq_file_name.Proteinmask.annot.stat.all`;
	#`perl $Bin/stat_TE.pl --protein $Outdir/$seq_file_name.Proteinmask.annot --rank type > $Outdir/$seq_file_name.Proteinmask.annot.stat.type`;
	#`perl $Bin/stat_TE.pl --protein $Outdir/$seq_file_name.Proteinmask.annot --rank subtype > $Outdir/$seq_file_name.Proteinmask.annot.stat.subtype`;
	#`perl $Bin/stat_TE.pl --protein $Outdir/$seq_file_name.Proteinmask.annot --rank family > $Outdir/$seq_file_name.Proteinmask.annot.stat.family`;
}


##`rm -r $Outdir/$seq_file_name.cut/`;
