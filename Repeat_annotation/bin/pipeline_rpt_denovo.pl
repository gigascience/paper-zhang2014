#!/usr/bin/perl -w
=head1 Description and Usage
        pipeline_rpt_denovo.pl --> to denovo and annotate the Scaf 

    Eg. perl pipeline_rpt_denovo.pl <sample.list> <config.file> <data.path> [options]

=head1 About
        Created at 04/16/14 11:18:57, by LiHui (@lihui5)
=cut
use strict;
use Getopt::Long;
use File::Basename qw(basename dirname) ;
use Cwd 'abs_path';
use FindBin '$Bin';
use List::Util qw(min max);
use Data::Dumper;
use lib "~/bin/lib" ;
use Storable qw(dclone);

my ($Help, $Step);
GetOptions(
        "help!"  => \$Help,
        "step:s" => \$Step
);
die `pod2text $0` if ($Help || @ARGV == 0);

#===================== Global Variable =====================#
my $fsam = shift;
my $fcof = shift;
my $data = shift;
my $pwd = `pwd` ;
chomp $pwd ;

#===================== Main process =====================#
my %sam = sample_list ($fsam) ; ## sub 1
my ($shrun,$runout) = ("$pwd/run.sh","") ;
my ($ddnv,$drpt) = ("$pwd/denovo","$pwd/repbase") ; 
my ($dnvf,$dnvo,$rptf,$rpto) = ("$ddnv/gff","$ddnv/out","$drpt/gff","$drpt/out") ; 
mkdir_dir($ddnv,$drpt,$dnvf,$dnvo,$rptf,$rpto) ; ## sub 2 

### create shells 
for my $i (sort keys %sam){
        my $idir = "$pwd/outdata" ;
        `mkdir $idir` unless (-e $idir) ;
        my $fii = "$idir/$i" ;
        `mkdir $fii` unless (-e $fii) ;
        my ($iscf) = $sam{$i} =~ /^(\S+)\.gz$/ ;
        my $fish = "$fii/s$i.sh" ;
        my ($fiout) = $iscf =~ /^([^\.]+)\./ ;
		$fiout = "$fii/$fiout.denovo.RepeatMasker.out" ;
		my $figff = $fiout ; 
		$figff =~ s/out$/gff/ ; 
		my $fioutk = $fiout ; 
		$fioutk =~ s/denovo\.(RepeatMasker)/known.$1/ ; 
		my $figffk = $fioutk ; 
		$figffk =~ s/out$/gff/ ; 
        my $iout = " gzip -dc $data/$sam{$i} > $fii/$iscf && echo gzip $i was OK\n" ;
        $iout .= " perl $Bin/denovo_repeat_find.pl -RepeatModeler $fii/$iscf && echo rptmd $i was OK \n" ;  ## denovo
        $iout .= " ln -s $fii/result/consensi.fa.classified $fii/final.library && echo ln -s $i was OK \n" ;
        $iout .= " perl $Bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib $fii/final.library $fii/$iscf && echo denovo annotation $i was OK \n" ;  ## denovo annotation
        $iout .= " perl $Bin/out_format.pl $fiout > $fiout.filter && echo filter denovo .out $i was OK \n" ;
		$iout .= " mv $fiout.filter $dnvo && mv $figff $dnvf && echo backup denovo \n" ; 
		$iout .= " perl $Bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g $fii/$iscf && echo repbase annotation $i was OK \n " ; ## repbase annotation
		$iout .= " perl $Bin/out_format.pl $fioutk > $fioutk.filter && echo filter repbase .out $i was OK \n" ; 
		$iout .= " mv $fioutk.filter $rpto && mv $figffk $rptf && echo backup repbase  $i \n"; 
        open OU,">$fish" || die $! ;
        print OU "#!/bin/sh\n$iout" ;
        close OU ;
        $runout .= " cd $fii && sh $fish && echo $i was OK [`date`]\n" ;
}

open SH,">$shrun" || die $! ;
print SH "#!/bin/sh\n$runout" ;
close SH ;

print STDERR "Please run the shell : $pwd/run.sh\n" ;
print STDERR "The final files : \n\t$pwd/denovo \n\t$pwd/repbase\n" ;

#=====================  Subroutines =====================#
## sub 2 
sub mkdir_dir {
	my @a = @_ ; 
	for my $i (@a){
		`mkdir $i ` unless (-e $i) ; 
	}
}
## sub 1
sub sample_list{
        my $f = shift;
        my %h ;
        open IN,$f || die $! ;
        while (<IN>){
                my ($a,$c) = (split)[0,2] ;
                $h{$a} = $c ;
        }
        close IN ;
        return %h;
}

