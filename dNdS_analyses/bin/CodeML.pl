#! /usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;
#use FindBin qw($Bin $Script);

sub usage {
	print <<USAGE;
usage:
	perl $0 [OPTIONS]
options:
	-help                   Print this help message.[NULL]
	-seqfile		sequence data filename.[*.phylip|*.nuc]
	-treefile		tree structure file name.
	-o|out			main result file name.
	-noisy			* 0,1,2,3,9: how much rubbish on the screen,[default noisy = 3]
	-verbose		* 1: detailed output, 0: concise output,[default verbose = 1]

	-runmode		[default runmode = 0]
				* 0: user tree; 1: semi-automatic; 2: automatic 
 				* 3: StepwiseAddition; (4,5):PerturbationNNI; -2: pairwise

	-seqtype		* 1:codons; 2:AAs; 3:codons-->AAs,[default seqtype = 1]
	-CodonFreq		* 0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table,[default CodonFreq = 2]
	-clock			* 0:no clock, 1:clock; 2:local clock; 3:TipDate,[default clock = 0]

	-model			[default model = 0]
				    * models for codons: 
					 * 0:one, 1:b, 2:2 or more dN/dS ratios for branches 
				    * models for AAs or codon-translated AAs: 
					 * 0:poisson, 1:proportional,2:Empirical,3:Empirical+F 
					 * 6:FromCodon, 8:REVaa_0, 9:REVaa(nr=189)

	-NSsites		[default NSsites = 0]
				    * 0:one w;1:neutral;2:selection; 3:discrete;4:freqs; 
				    * 5:gamma;6:2gamma;7:beta;8:beta&w;9:beta&gamma; 
				    * 10:beta&gamma+1; 11:beta&normal>1; 12:0&2normal>1; 
				    * 13:3normal>0

	-icode			* 0:universal code; 1:mammalian mt; 2-11:see below,[default icode = 0]
	-fix_kappa		* 1: kappa fixed, 0: kappa to be estimated,[default fix_kappa = 0]
	-kappa			* initial or fixed kappa,[default kappa = 4.54006 ]
	-fix_omega		* 1: omega or omega_1 fixed, 0: estimate,[default fix_omega = 0]
	-omega			* initial or fixed omega, for codons or codon-based AAs,[default omega = 1]
	-fix_alpha		* 0: estimate gamma shape parameter; 1: fix it at alpha,[fix_alpha = 1]
	-alpha			* initial or fixed alpha, 0:infinity (constant rate),[alpha = 0]
	-Malpha			* different alphas for genes,[Malpha = 0]
	-ncatG			* # of categories in dG of NSsites models,[ncatG = 4]
	-getSE			* 0: don't want them, 1: want S.E.s of estimates,[getSE = 0]
	-RateAncesto		* (0,1,2): rates (alpha>0) or ancestral states (1 or 2)[RateAncesto = 0]
	-method			* 0: simultaneous; 1: one branch at a time,[method = 0]
	-fix_blength		* 0: ignore, -1: random, 1: initial, 2: fixed,[fix_blength = 1]
USAGE
}

my($noisy,$verbose,$runmode,$seqtype,$CodonFreq,$clock,$model,$NSsites,$icode,$fix_kappa,$kappa,$fix_omega,$omega,$fix_alpha,$alpha,$Malpha,$ncatG,$getSE,$RateAncesto,$method,$fix_blength)=(3,1,0,1,2,0,0,0,0,0,4.54006,0,1,1,0,0,4,0,0,1,1);
my($seqfile,$treefile,$help,$out);

GetOptions('h|help'      => \$help,
	   'seqfile=s'   => \$seqfile,
	   'treefile=s'  => \$treefile,
	   'o|out=s'	 => \$out,
	   'noisy=s'     => \$noisy,
	   'verbose=s'   => \$verbose,
	   'runmode=s'   => \$runmode,
	   'seqtype=s'   => \$seqtype,
	   'CodonFreq=s' => \$CodonFreq,
	   'clock=s'     => \$clock,
	   'model=s'	 => \$model,
	   'NSsites=s'   => \$NSsites,
           'icode=s'	 => \$icode,
           'fix_kappa=s' => \$fix_kappa,
           'kappa=f' 	 => \$kappa,
           'fix_omega=i' => \$fix_omega,
           'omega=i'     => \$omega,
           'fix_alpha=i' => \$fix_alpha,
           'alpha=i'	 => \$alpha,
           'Malpha=i'	 => \$Malpha,
           'ncatG=i'     => \$ncatG,
           'getSE=i'	 => \$getSE,
           'RateAncesto=i'=> \$RateAncesto,
           'method=i'	 => \$method,
           'fix_blength=i'=> \$fix_blength,
);

if($help || ($model>2)){
	print usage();
	exit();
}

unless($seqfile || $treefile || $out){
	print usage();
	exit();
}


my $dataDir ="$out"."_files";
$dataDir =~ s/\.dat//;

`mkdir -p $dataDir`;

open(IN,"$seqfile") or die "$!";
open(OUT,">$dataDir/seqfile") or die "$!";
while(<IN>){
	chomp;
	print OUT "$_\n";
}
close IN;close OUT;

my $tree;
open(IN,"$treefile") || die "$!";
open(OUT,">$dataDir/treefile") || die "$!";
while(<IN>){
	chomp ;
	$tree .= $_;
}

my $out_0=$out.'.m0.out';
my $out_2=$out.'.m2.out';
$out=$out_0;

if ($model == 2){
	$out=$out_2;
	if ($tree =~ /\s\#[0-9.]*/){
		print OUT "$tree\n";
	}	
	else{
		print STDERR "The species tree file must contains dN/dS ratioes for selectting branches,Please check your input tree file again!\n";
	}
}
else{
	print OUT "$tree\n";
}
close IN;close OUT;

open(Config,">$dataDir/config.ctl.m$model") || die "$!";
print Config "
                seqfile = seqfile
                treefile = treefile
                outfile = $out
                noisy = $noisy
                verbose = $verbose
                runmode = $runmode
                seqtype = $seqtype
                CodonFreq = $CodonFreq
                clock = $clock
                model = $model
                NSsites = $NSsites
                icode = $icode
                fix_kappa = $fix_kappa
                kappa =  $kappa
                fix_omega = $fix_omega
                omega = $omega
                fix_alpha = $fix_alpha
                alpha = $alpha
                Malpha = $Malpha
                ncatG = $ncatG
                getSE = $getSE
                RateAncestor = $RateAncesto
                method = $method
                fix_blength = $fix_blength
                ";
close Config;

if(system("cd $dataDir; ../bin/codeml config.ctl.m$model >codeml.log")){
	print STDERR "Unfinish: CodeML running error!\n";
}
