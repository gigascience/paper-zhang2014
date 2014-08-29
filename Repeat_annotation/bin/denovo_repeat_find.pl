#!/usr/bin/perl
=head1  Name

	denovo_repeat_find.pl -- the pipeline of denovo predict repeat in sequences.

=head1 Description

	This programm is to denovo predict the repeat sequences (mainly the transponse elements),which contains the softwares such as PILER,
	RepeatScout,LTR_FINDER and RepeatModeler.You can choose one of these program or all of them according to the vary genome.
	
=head1 Usage:
	
	For small genome sequence(<=600M),you'd better choose the piler and RepeatScout for denovo repeat library construction;and for other genome 
	sequences,you'd better choose the RepeatModeler.The LTR_FINDER is selectable.

=head1 example

	perl denovo_repeat_find.pl -Piler -RepeatScout -LTR_FINDER -RepeatModeler ./test.fa

=head1 Information
	
	Author: 	caiql     		caiql@genomics.org.cn
	Mender:		zhouheling     	zhouheling@genomics.cn
	Version:	1.0
	Update1:	2009-07-09
	Update2:	2010-03-10
	Update3:	2010-05-06	(repair RepeatModeler)

=head1 Usage

        perl denovo_repeat_find.pl [options] input_file
        -Piler                  run Piler
        -RepeatScout            run RepeatScout
        -LTR_FINDER             run LTR_FINDER
        -tRNA <str>             set tRNA lib
        -cpu <int>              set the cpu number to use in parallel, default=3
		--queue <str>     specify the queue to use, default no
        -run <str>              set the parallel type, qsub or multi, default=qsub
		-node <str>            set the compute node, eg h=compute-0-151,default is not set
        -cutf <int>             cut file with the specified number of subfile in total
        -cuts <int>             cut file with the specified number of seqeunces in each sub file
        -RepeatModeler          run RepeatModeler
        -All_method             run all method
        -resource <str>         set the required resource used in qsub -l option, default vf=3G
        -verbose                output verbose information to screen
        -help                   output help information to screen.

=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Data::Dumper;
use lib "$Bin/lib";
use GACP qw(parse_config);

my ($piler,$repeatscout,$Queue,$Run,$Node,$tRNA,$ltr_finder,$repeatmodeler,$all,$Cpu,$Resource,$cutf,$cuts,$config,$Verbose,$help);
GetOptions(
	"Piler"=>\$piler,
	"RepeatScout"=>\$repeatscout,
	"LTR_FINDER"=>\$ltr_finder,
	"tRNA:s"=>\$tRNA,
	"cpu:i"=>\$Cpu,
	"queue:s"=>\$Queue,
	"run:s"=>\$Run,
	"node:s"=>\$Node,
	"cutf:i"=>\$cutf,
	"cuts:i"=>\$cuts,
	"RepeatModeler"=>\$repeatmodeler,
	"All_method"=>\$all,
	"resource:s"=>\$Resource,
	"verbose"=>\$Verbose,
	"help"=>\$help
);
die `pod2text $0` if(@ARGV==0 || $help);

$Cpu ||= 2;
$Run ||= "qsub";
$cuts ||=100;
$cutf||=20;
$Resource ||= "vf=3G";

my $seq_file=shift;

my $seq_name=basename($seq_file);
my $species_name=$1 if ($seq_name=~/^(\w+)\./);
my $config_file="$Bin/../config.txt";
my $common_bin = $Bin;
my $fastaDeal = "$common_bin/fastaDeal.pl";
my $find_repeat=parse_config($config_file,"find_repeat");

##############	PILER PATH	#############################################
my $pals_path=parse_config($config_file,"pals_path");
my $piler_path=parse_config($config_file,"piler_path");
my $Piler=parse_config($config_file,"piler");
my $muscle_path=parse_config($config_file,"muscle");

##############	RepeatScout	PATH	#####################################
my $repeatscout_path=parse_config($config_file,"repeatscout_path");
my $repeatmasker_path=parse_config($config_file,"repeatmasker");

##############	RepeatModeler	PATH	#####################################
my $repeatmodeler_path=parse_config($config_file,"repeatmodeler_path");

##############	LTR_FINDER	PATH	#####################################
my $ltr_path=parse_config($config_file,"ltr_path");
$tRNA ||= "$ltr_path/tRNAdb/Athal-tRNAs.fa";
my $dir=`pwd`;
chomp $dir;
#print "$dir";

##################################################
##################################################
##################################################
if(defined $piler){
		my $outdir=$dir."/Piler_Result";
		mkdir $outdir unless (-d $outdir);
		my $hit=$outdir."/".$seq_name.".hit.gff";
		my $trs=$outdir."/".$seq_name.".hit.trs.gff";
		my $fams=$outdir."/".$seq_name."_families";
		my $cons=$outdir."/".$seq_name."_cons";
		my $aligned_fams=$outdir."/".$seq_name."_aligned_fams";
		my $library=$outdir."/".$seq_name.".piler_library.fa";
		my $log=$outdir."/".$seq_name.".piler.log";
		my $piler_shell=$outdir."/"."Run_piler_for_$seq_name.sh";
		my $cut= $dir."/".$seq_name.".cut/";
		`ln -s $seq_file` unless (-e $seq_name);
		my $num=`grep -c ">"  $seq_name`; 
		`perl $fastaDeal --cutf $cutf $seq_name` if($num<=4000);
		`perl $fastaDeal --cuts $cuts $seq_name` if($num>4000);
		my $pipeline="$Piler/pipeline.pl";
		`perl $pipeline $cut`;
		`perl $common_bin/multi-process.pl  -cpu $Cpu  find_pals.sh` if($Run eq "multi");
		if(defined $Node){
			`perl $common_bin/qsub-sge.pl  -maxjob $Cpu --resource $Resource --node $Node -reqsub --convert no find_pals.sh` if($Run eq "qsub");
		}
		else{
		`perl $common_bin/qsub-sge.pl  -maxjob $Cpu --resource $Resource  -reqsub --convert no find_pals.sh` if($Run eq "qsub");}
		`cat find_pals.sh.*.qsub/pals*.log >pals.log`;
                `cat find_pals.sh.*.qsub/pals*.log2 >pals.log2`;
                `cat find_pals.sh.*.qsub/*.hit.gff > final.all.hit.gff`;
		`mv final.all.hit.gff $hit` if ($Run eq "multi");
		`rm *.gff` if ($Run eq "multi");
		`mv final.all.hit.gff $hit` if ($Run eq "qsub");
		`$piler_path -trs $hit -out $trs 1>>$log`;
		if(-d $fams){`rm -fr $fams`;}
		unless(-d $fams){`mkdir $fams`;}
		`$piler_path -trs2fasta $trs -seq $seq_file -path $fams >>$log`;

		if(-d $aligned_fams){`rm -fr $aligned_fams`;}
		unless(-d $aligned_fams){`mkdir $aligned_fams`;}
		opendir THIS,$fams or die "$!";
		my @family=readdir THIS;
		closedir THIS;
		
		foreach my $fam(@family)
		{
			my $full_name="$fams/$fam";
			my $name=basename($fam);
			my $out="$aligned_fams/$name";
			`$muscle_path -in $full_name -out $out -maxiters 1 -diags 1>>$log ;`
		}
		
		if(-d $cons){`rm -fr $cons`;} 
		unless(-d $cons){print OUT `mkdir $cons`;}
		
		opendir THIS,$aligned_fams or die "$!"; 
		my @consensus=readdir THIS;
		closedir THIS;
		
		foreach my $con(@consensus)
		{
				my $full_name="$aligned_fams/$con";
				my $name=basename($con);
				my $out="$cons/$name"; 
				`$piler_path -cons $full_name -out $out -label $con 1>>$log`;
				`cat $out >> $library`;
		}
}

##################################################
##################################################
##################################################
if(defined $repeatscout){
		my $outdir=$dir."/RepeatScout";
		mkdir $outdir unless(-d $outdir);
		`ln -s $seq_file` unless (-e $seq_name);
		my $repscout=$outdir."/".$seq_name.".17mer.repeatscout";
		my $freq=$outdir."/".$seq_name.".17mer.tbl";
		my $filter=$repscout.".filter";
		my $out=$outdir."/".$seq_name.".out";
		my $library=$filter.".library.fa";
		my $log=$outdir."/".$seq_name.".17mer.repeatscout.log";
		open OUT1,">build_lmer_table.sh" or die "$!";
		open OUT,"> repeatscout.sh" or die "$!";
		print OUT1 "$repeatscout_path/build_lmer_table -l 17 -sequence $seq_file -freq $freq 1 >> $log\n";
		open OUT2, ">repeatscout_out.sh"or die "$!";
		print OUT2 "$repeatscout_path/RepeatScout -sequence $seq_file -output $repscout -freq $freq -l 17 1 >> $log\n";
		if(defined $Node){
			print OUT "perl $common_bin/qsub-sge.pl --lines 1 --resource  vf=3G --node $Node -reqsub  build_lmer_table.sh \n";
		}
		else{print OUT "perl $common_bin/qsub-sge.pl --lines 1 --resource  vf=3G  -reqsub  build_lmer_table.sh \n";}	
		if(defined $Node){
			print OUT "perl $common_bin/qsub-sge.pl --lines 1 --resource  vf=3G --node $Node  -reqsub  repeatscout_out.sh  \n";
		}
		else{ print OUT "perl $common_bin/qsub-sge.pl --lines 1 --resource  vf=3G  -reqsub  repeatscout_out.sh  \n";}	
		print OUT "cat $repscout | $repeatscout_path/filter-stage-1.prl 1>$filter 2>>$log\n";
		print OUT "$repeatmasker_path -nolow -no_is -norna -parallel 1 -lib $filter $seq_file 1>>$log\n  mv $seq_name.RepeatMasker.out $out\n" if($Run eq "multi");
		if(defined $Node){
			print OUT "$find_repeat -repeatmasker -cutf $cutf -cpu $Cpu -node $Node -lib $filter $seq_name\n mv $species_name.denovo.RepeatMasker.out $out\n" if($Run eq "qsub");
		}
		else{ print OUT "$find_repeat -repeatmasker -cutf $cutf -cpu $Cpu  -lib $filter $seq_name\n mv $species_name.denovo.RepeatMasker.out $out\n" if($Run eq "qsub");}
		print OUT "cat $filter |$repeatscout_path/filter-stage-2.prl --cat=$out --thresh=20 1>$library  2>>$log";
		close OUT;
		close OUT1;
		`sh repeatscout.sh`;
}

##################################################
##################################################
##################################################
if(defined $repeatmodeler)
{
		my $log=$seq_name.".repeatmodeler.log";
		my $rmd_shell="Run_repeatModeler_for_$seq_name.sh";
		open OUT , ">$rmd_shell" or die "$!";
		print OUT "#!/bin/bash\n";
		print OUT "$repeatmodeler_path/BuildDatabase -name mydb $seq_file > $log \n";
		print OUT "$repeatmodeler_path/RepeatModeler -database mydb > run.out\n";
		print OUT "rm -r RM_*/round-*\n";
		print OUT "mv RM_* result\n";
		close OUT;
		my $temp_node;
		if(defined $Node){
			$Node= "-l $Node";
			`nohup  qsub -cwd -l vf=5G $Node -P tc_fun $rmd_shell\n`;  ## -P  
		}
		else { `nohup  qsub -cwd -l vf=5G -P tc_fun  $rmd_shell\n`;}  ## -P 

}	

##################################################
##################################################
##################################################
if(defined $ltr_finder)
{
	my $outdir=$dir."/LTR_Result";
	mkdir $outdir unless(-d $outdir);
	`ln -s $seq_file` unless (-e $seq_name);
	my $cut= $dir."/".$seq_name.".cut/";
	`perl $fastaDeal --cutf  $cutf  $seq_name`;
	opendir DIR,$cut or die "$!";
	my @fa= grep {/$seq_name/} readdir DIR;
	closedir DIR;
	my $ltr_shell="Run_LTR_FINDER_for_$seq_name.shell";
	open OUT,">$ltr_shell" or die "$!";
	foreach my $subfa(@fa)
	{
		my $ltr=$outdir."/".$subfa."ltr_finder";
		my $gff=$ltr.".gff";
		my $log="$outdir/$subfa.ltr_finder.log";
		my $cut_file="$cut$subfa";
		print OUT "$ltr_path/ltr_finder  -w 2 -s $tRNA  $cut_file 1>$ltr 2>>$log; ";
		print OUT "perl $ltr_path/Ltr2GFF.pl $ltr 1>$gff 2>>$log; ";
		print OUT "$common_bin/getTE.pl $gff $cut_file > $outdir/$subfa.LTR.fa\n";
	}
	print OUT "cat $outdir/*.LTR.fa> $seq_name.LTR.fa\;";
	print OUT "cat $outdir/*ltr_finder.gff >$seq_name.ltr_finder.gff\;";
	close OUT;
                if(defined $Node){
			$Node= "-l $Node";
			`nohup  qsub -cwd -l vf=3G $Node -P tc_fun $ltr_shell\n`;	## -P 
		 }
		else { `nohup  qsub -cwd -l vf=3G -P tc_fun $ltr_shell\n`;}   ## -P 
}
