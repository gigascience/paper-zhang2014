#!/usr/bin/perl


=head1 NAME
	
protein_map_genome.pl  --  the pipeline of mapping protein to genome for draft sequence.

=head1 DESCRIPTION

This script invokes tblastn, genBlastA, and genewise, and finally
give result in gff3 format.

The total time sometimes depends on the some tasks of genewise,
which becomes very slowly when the protein and DNA sequence is
too large. 

Alert that in this program, "|"  in protein name is not allowed.
All sequence must be in fasta format ,and head line should be include ID only.
Otherwise,genBlastA will make a big error !
So,before running this pipeline,you shuld run $Bin/SimpleID.pl to simplify sequences ID.


=head1 Version

  Author:	Huang Quanfei,huangqf@genomics.org.cn
		Liu Shiping,liushiping@genomics.org.cn

  Version: 2.0  Date: 2009-6-3
  Update: 2.1 2010-07-26
  Update: 2.2 2010-09-19
  Update: V8.1 2013-11-30, can read compressed fasta (*.fa.gz for genome and pep files) directly.

=head1 Usage

    perl protein_map_genome.pl [options] protein.fa genome.fa
    --cpu <int>	         set the cpu number to use in parallel, default=100
    --run <str>          set the parallel type, qsub, or multi, default=qsub
    --outdir <str>       set the result directory, default="./"
    --tophit <num>       select best hit for each protein, default no limit
    --blast_eval <num>   set eval for blast alignment, default 1e-2
    --align_rate <num>   set the aligned rate for solar result, default 0.01
    --filter_rate <num>	 set the filter rate for the best hit of geneblastA result,default 0.7
    --extend_len <num>   set the extend length for genewise DNA fragment ,default 500
    --step <num>         set the start step for running(1234567), default 1234
    --net <str>		 set the net directory result.
    --rgene <str>	 set the reference gene file with GFF3 format.
    --queue <str>        set the queue ,default no
    --lines <int>        set the --lines option of qsub-sge.pl, default 200
    --resource <vf=XXG>	 set the qsub-sge commond.default vf=1.0G
    --reqsub		 set the qsub-sge commond.default no
    --verbose            output verbose information to screen,default no  
    --help               output help information to screen,default no

=head1 Example

  perl ../bin/protein_map_genome.pl -cpu 100 -verbose ../input/Drosophila_melanogaster_protein.1000.fa ../input/test_chr_123.seq &


=cut


use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use lib "$Bin/../lib";
use Data::Dumper;
use File::Basename qw(basename dirname); 
use YAML qw(Load Dump);
use List::Util qw(reduce max min);
use Collect qw(Read_fasta);

##get options from command line into variables and set default values
my ($Cpu,$Run,$Outdir,$Net,$Ref_gene);
my ($Blast_eval,$Align_rate,$Filter_rate,$Extend_len,$Step);
my ($Cpu,$Resource,$Reqsub,$Verbose,$Help);
my $Queue;
my $Line;
GetOptions(
	"lines:i"=>\$Line,
	"cpu:i"=>\$Cpu,
	"run:s"=>\$Run,
	"outdir:s"=>\$Outdir,
	"blast_eval:s"=>\$Blast_eval,
	"align_rate:f"=>\$Align_rate,
	"filter_rate:f"=>\$Filter_rate,
	"extend_len:i"=>\$Extend_len,
	"step:s"=>\$Step,
	"net:s"=>\$Net,
	"rgene:s"=>\$Ref_gene,
	"cpu:i"=>\$Cpu,
	"queue:s"=>\$Queue,
	"resource:s"=>\$Resource,
	"reqsub!"=>\$Reqsub,
	"verbose!"=>\$Verbose,
	"help!"=>\$Help
);
$Blast_eval ||= 1e-2;
$Align_rate ||= 0.01;
$Filter_rate ||= 0.7;
$Extend_len ||= 500;
$Step ||= '1234';
$Step =~ s/5//g unless(-d "$Net" && -e "$Ref_gene");
$Cpu ||= 100;
$Line ||= 200;
$Resource ||= "vf=1.5G";
$Run ||= "qsub";
$Outdir ||= ".";
my $Queue_para=(defined $Queue)?"-queue $Queue":'';
$Queue_para .= " --reqsub" if $Reqsub;
$Queue_para .= " --resource $Resource" if $Resource;
die `pod2text $0` if (@ARGV == 0 || $Help || (not defined $Line ));

my $Qr_file = shift;
my $Db_file = shift;

my %Pep_len;
read_fasta($Qr_file,\%Pep_len);

my %Chr_len;
read_fasta($Db_file,\%Chr_len);

$Outdir =~ s/\/$//;
mkdir($Outdir) unless(-d $Outdir);

my $Qr_file_basename = basename($Qr_file);
my $genewise_dir = "$Outdir/$Qr_file_basename.genewise";

my $tblastn_shell_file = "$Outdir/$Qr_file_basename.tblastn.shell";
my $genewise_shell_file = "$Outdir/$Qr_file_basename.genewise.shell";

my @subfiles;
my $GBPATH="$Bin/genBlastA";

my %config;
parse_config("$Bin/config.txt",\%config);

##use YAML format to set parameters for blastall, solar, filter, and genewise programs
my $Param = Load(<<END);
blastall:
  -p: tblastn
  -e: $Blast_eval
  -F: F
filter-solar:
  extent: $Extend_len
genewise:
  -genesf:
  -gff:
  -sum:
END
print STDERR Dump($Param) if($Verbose);
print STDERR "step = $Step\n" if($Verbose);

if ($Step =~/1/){
	##format the database for tblastn
	`$config{formatdb} -i $Db_file -p F -o T` unless (-f $Db_file.".nhr");

	##cut query file into small subfiles
	`perl $Bin/fastaDeal.pl -cutf $Cpu $Qr_file -outdir $Outdir`;
	@subfiles = glob("$Outdir/$Qr_file_basename.cut/*.*");

	##creat the tblastn shell file
	my $opt_blastall = join(" ",%{$Param->{blastall}});
	open OUT,">$tblastn_shell_file" || die "fail $tblastn_shell_file";
	foreach my $qrfile (@subfiles) {
		print OUT "$config{blastall} $opt_blastall -d $Db_file -i $qrfile -o $qrfile.blast; \n";
	}
	close OUT;

	print STDERR "run the tblastn shell file"  if($Verbose);
	if ($Run eq "qsub") {
		`perl $Bin/qsub-sge.pl  $Queue_para --maxjob $Cpu   $tblastn_shell_file`;
	}
	if ($Run eq "multi") {
		`perl $Bin/multi-process.pl -cpu $Cpu $tblastn_shell_file`;
	}

	##cat together the tblastn result
	`cat $Outdir/$Qr_file_basename.cut/*.blast > $Outdir/$Qr_file_basename.blast`;
}

if ($Step =~/2/){
	print  STDERR "run genBlastA to conjoin HSPs\n"  if($Verbose);
	`ln -s $Qr_file` if ( not -f "./$Qr_file_basename"); 
	`$GBPATH/genblasta -q ./$Qr_file_basename -t $Db_file -p T -e $Blast_eval -g T -f F -a 0.5 -d 100000 -r 100 -c $Align_rate -s -100 -o ./$Qr_file_basename.genblast.out > ./$Qr_file_basename.genblast.out.log 2> ./$Qr_file_basename.genblast.out.err`; 
	&convert_out("./$Qr_file_basename.genblast.out","./$Qr_file_basename.genblast.tab");
#	`perl $Bin/filter_genblastA_tab.pl -l 20 -p 25 ./$Qr_file_basename.genblast.tab > ./$Qr_file_basename.genblast.tab.best`;
	`perl $Bin/filter.tab.pl ./$Qr_file_basename.genblast.tab $Filter_rate > ./$Qr_file_basename.genblast.tab.best`;
#	`ln -s ./$Qr_file_basename.genblast.tab ./$Qr_file_basename.genblast.tab.best`;
}

if ($Step =~/3/){
	print STDERR "preparing genewise input directories and files\n" if ($Verbose);
	&prepare_genewise("$Outdir/$Qr_file_basename.genblast.tab.best","$Ref_gene");

	print STDERR "run the genewise shell file\n" if ($Verbose);
	`perl $Bin/fastaDeal.pl -attr id:len $Qr_file > $Outdir/$Qr_file_basename.len`;
	`perl $Bin/classBigProtein.pl $genewise_shell_file $Outdir/$Qr_file_basename.len $Outdir`;
	if ($Run eq "qsub") {
		`perl $Bin/qsub-sge.pl  --reqsub --resource vf=0.5g  --maxjob $Cpu --lines $Line   $genewise_shell_file.st1k.shell`;
		my $Line_2=int($Line/10);
		$Line_2=1 if($Line_2 < 1);
		`perl $Bin/qsub-sge.pl  --reqsub --resource vf=0.5g  --maxjob $Cpu --lines $Line_2 $genewise_shell_file.bt1k.shell`;
		`perl $Bin/qsub-sge.pl  --reqsub --resource vf=0.5g  --maxjob $Cpu --lines 1 $genewise_shell_file.bt3k.shell`;
	}
	if ($Run eq "multi") {
		`perl $Bin/multi-process.pl -cpu $Cpu $genewise_shell_file`;
	}
}

if ($Step =~/4/){
	print  STDERR "convert result to gff3 format\n"  if($Verbose);
	`for i in $Outdir/$Qr_file_basename.genewise/* ;do for k in \$i/* ;do for j in \$k/*.genewise ;do cat \$j;done ;done ;done >$Outdir/$Qr_file_basename.genblast.genewise`;
	`perl $Bin/fastaDeal.pl -attr id:len $Qr_file >$Outdir/$Qr_file_basename.len`;
	`perl  $Bin/gw2gffWithShift.pl $Outdir/$Qr_file_basename.genblast.genewise $Outdir/$Qr_file_basename.len >$Outdir/$Qr_file_basename.genblast.genewise.gff`;
#	`perl $Bin/filter_gff_gene_lenght.pl --threshold 100 --exons 2 --score 50 $Outdir/$Qr_file_basename.genblast.genewise.gff > $Outdir/$Qr_file_basename.genblast.genewise.filter.gff`;
	`ln -s $Outdir/$Qr_file_basename.genblast.genewise.gff $Outdir/$Qr_file_basename.genblast.genewise.filter.gff`;
	`perl $Bin/gw2support.pl $Outdir/$Qr_file_basename.genblast.genewise $Outdir/$Qr_file_basename.len > $Outdir/$Qr_file_basename.genblast.genewise.support`;
	`perl $Bin/gw2support.pl.change $Outdir/$Qr_file_basename.genblast.genewise $Outdir/$Qr_file_basename.len > $Outdir/$Qr_file_basename.genblast.genewise.support2`;
}

if ($Step =~ /5/){
	print STDERR "running Synteny ...\n" if ($Verbose);
	my $netdir="$Outdir/net2tab";
	`mkdir $netdir` unless(-d "$netdir");
	my @nets=<$Net/*>;
	for (@nets){
		my $netname=basename $_;
		`perl $Bin/net2tab.pl $_ > $netdir/$netname.tab`;
		`perl $Bin/filter_redundance.pl $netdir/$netname.tab $netdir 100`;
		`rm $netdir/$netname.tab`;
	}
	undef @nets;
	my @nets=<$netdir/*.nr.tab>;
	open SySH,">$Outdir/$Qr_file_basename.genblast.genewise.gff.SyShell" or die $!;
	for (@nets){
		my $netname=basename $_;
		print SySH "perl $Bin/prepareFor.pl $_ $Ref_gene $Outdir/$Qr_file_basename.genblast.genewise.gff\n";
	}
	close SySH;

	if ($Run eq "qsub") {
		`perl $Bin/qsub-sge.pl --lines 1 --reqsub --maxjob $Cpu --resource vf=0.9g $Outdir/$Qr_file_basename.genblast.genewise.gff.SyShell`;
	}
	if ($Run eq "multi") {
		`perl $Bin/multi-process.pl -cpu $Cpu $Outdir/$Qr_file_basename.genblast.genewise.gff.SyShell`;
	}
	`for i in $netdir/*.nr.tab;do cat \$i;done > $Outdir/$Qr_file_basename.genblast.genewise.gff.nr.net2tab`;
	`for i in $netdir/*.Synteny;do cat \$i;done > $Outdir/$Qr_file_basename.genblast.genewise.gff.Synteny.list`;
	`for i in $netdir/*.out;do cat \$i;done > $Outdir/$Qr_file_basename.genblast.genewise.gff.Synteny.out`;
#	`rm -rf $netdir`;
	`perl $Bin/fishInWinter.pl -bf table -bc 2 -ff gff $Outdir/$Qr_file_basename.genblast.genewise.gff.Synteny.out $Outdir/$Qr_file_basename.genblast.genewise.gff > $Outdir/$Qr_file_basename.genblast.genewise.gff.Synteny.gff`;
}

if ($Step =~ /6/){
	my $GFF="$Outdir/$Qr_file_basename.genblast.genewise.filter.gff";
	print STDERR "Running Muscle for getting identitive ...\n" if ($Verbose);
	`perl $Bin/product_di_lst.pl $GFF > $GFF.id.list`;
	`perl $Bin/getGene.pl $GFF $Db_file > $GFF.cds`;
	`perl $Bin/cds2aa.pl $GFF.cds > $GFF.pep`;
	`perl $Bin/run_muscle.pl $GFF.id.list $GFF.pep $Qr_file`;
	`perl $Bin/qsub-sge.pl --lines $Line --reqsub --maxjob $Cpu --resource vf=0.5g $GFF.id.list.muscle.sh`;
	`for i in $GFF.id.list.cut*/*;do for j in \$i/*;do for k in \$j/*.muscle;do perl $Bin/muscle_identity.pl \$k;done;done;done > $GFF.ident.list`;
#	`perl $Bin/run_muscle.ide.pl $GFF.id.list.cut* > $GFF.ident.list`;
	`awk '\$3 >= 30 && \$6 >= 50 && \$7 >= 10 && \$8 >= 25' $GFF.ident.list > $GFF.ident.list.filter`;
#	`rm -rf $GFF.id.list.cut*`;
}

if ($Step =~ /7/){
	my $GFF="$Outdir/$Qr_file_basename.genblast.genewise.filter.gff";
	print STDERR "Running extend gene and remove pseudo shift ...\n" if ($Verbose);
	`perl $Bin/filterShiftN.pl $GFF $Db_file > $GFF.noShift`;
	`perl $Bin/extendEnds.pl $GFF $GFF.ident.list.filter $Db_file > $GFF.Extend.gff 2> $GFF.Extend.log`;
	`perl $Bin/noShiftGff.pl $GFF.noShift $GFF.Extend.gff > $GFF.noShiftExt.gff`;
}

print  STDERR "All tasks finished\n"  if($Verbose);


####################################################
################### Sub Routines ###################
####################################################

##read sequences in fasta format and calculate length of these sequences.
sub read_fasta{
	my ($file,$p)=@_;
	if($file =~ /\.gz$/){
		open IN,"gzip -dc $file|" or die $!;
	}else{
		open IN,$file or die "Fail $file:$!";
	}
	$/=">";<IN>;$/="\n";
	while(<IN>){
		my ($id,$seq);
		if ($file eq $Qr_file && /\S\s+\S/ ) {
			die "No descriptions allowed after the access number in header line of fasta file:$file!\n";
		}
		if ( /\|/ ){
			die "No '|' allowed in the access number of fasta file:$file!\n";
		}
		
		if (/^(\S+)/){
			$id=$1;
		}else{
			die "No access number found in header line of fasta file:$file!\n";
		}
		$/=">";
		$seq=<IN>;
		chomp $seq;
		$seq=~s/\s//g;
		$p->{$id}=length($seq);
		$/="\n";
	}
	close IN;
}

##parse the software.config file, and check the existence of each software
####################################################
sub convert_out{
        my($infile,$outfile)=@_;
	$/="//******************END*******************//";
	my %match;
        open IN,$infile or die "Fail $infile:$!";
    while(<IN>){
		chomp;
		my @Lines=split(/\n/);
		my ($pep_id,$chr_id,$chr_start,$chr_end,$strand,$rank);
		my ($hsp_id,$hsp_chr_start,$hsp_chr_end,$hsp_pep_start,$hsp_pep_end,$identity);
		$rank=0;
		foreach my $line(@Lines){
			next if ($line!~/\S/ || $line=~/^\/\//);
			#if ($line=~/^(\S+)\|(\S+)\s+.*:(\d+)\.\.(\d+)\|(\+|-)\|gene cover:\d+\(\S+\)\|score:.+rank:(\d+)/){
           	if ($line=~/^(\S+)\|(\S+).*:(\d+)\.\.(\d+)\|(\+|-)\|gene cover:\d+\(\S+\)\|score:.+rank:(\d+)/){ # change by Shiping Liu, 2012.6.26
				$rank++;
				($pep_id,$chr_id,$chr_start,$chr_end,$strand)=($1,$2,$3,$4,$5);
				$match{"$pep_id\-D$rank"}{chr}=$chr_id;
				$match{"$pep_id\-D$rank"}{strand}=$strand;
				@{$match{"$pep_id\-D$rank"}{chr_pos}}=($chr_start,$chr_end);
            }elsif($line=~/^HSP_ID\[(\d+)\]:\((\d+)-(\d+)\);query:\((\d+)-(\d+)\);\spid: (\S+)/){
				($hsp_id,$hsp_chr_start,$hsp_chr_end,$hsp_pep_start,$hsp_pep_end,$identity)=($1,$2,$3,$4,$5,$6);
				push @{$match{"$pep_id\-D$rank"}{hsp}},[$hsp_pep_start,$hsp_pep_end,$hsp_chr_start,$hsp_chr_end,$identity];
			}	
		}
    } 
	close IN;
	$/="\n";
	
	my $output;
	foreach my $id (sort keys %match){
#		print $id."\n";
		@{$match{$id}{hsp}}=sort{$a->[0]<=>$b->[0]} @{$match{$id}{hsp}};
		my ($pep_start,$pep_end)=($match{$id}{hsp}[0][0],$match{$id}{hsp}[-1][1]);
		my $real_id;
		if ($id=~/^(\S+)-D(\d+)$/){
			$real_id=$1;
		}else{
			$real_id=$id;
		}
		my ($str,$chr)=($match{$id}{strand},$match{$id}{chr});
		my $hsp_num=scalar(@{$match{$id}{hsp}});
		$output.=join("\t",$id,$Pep_len{$real_id},$pep_start,$pep_end,$str,$chr,$Chr_len{$chr},@{$match{$id}{chr_pos}},$hsp_num)."\t";
		my ($total_ide,$total_hsp_len)=(0,0);
		my ($hsp_pos_out,$chr_pos_out,$hsp_ide_out);
		my @pos;
		for(my $i=0;$i<$hsp_num;$i++){
			push @pos,[@{$match{$id}{hsp}[$i]}[0,1]];
			$total_ide+=(abs($match{$id}{hsp}[$i][1]-$match{$id}{hsp}[$i][0])+1)*$match{$id}{hsp}[$i][4];
			$total_hsp_len+=abs($match{$id}{hsp}[$i][1]-$match{$id}{hsp}[$i][0])+1;	
			$hsp_pos_out.=join(",",@{$match{$id}{hsp}[$i]}[0,1]).";";
			$chr_pos_out.=join(",",@{$match{$id}{hsp}[$i]}[2,3]).";";
			$hsp_ide_out.=sprintf("%.2f",$match{$id}{hsp}[$i][4]).";";
		}
		my $identity=sprintf("%.2f",$total_ide/$total_hsp_len);
		my $coverage=sprintf("%.2f",Conjoin_fragment(\@pos)/$Pep_len{$real_id}*100);
		$output.=join("\t",$coverage,$hsp_pos_out,$chr_pos_out,$hsp_ide_out)."\n";			
	}
	
        open OUT,">$outfile" or die "Fail $outfile:$!";
        print OUT $output;
        close OUT;
}

sub parse_config{
	my $conifg_file = shift;
	my $config_p = shift;
	
	my $error_status = 0;
	open IN,$conifg_file || die "fail open: $conifg_file";
	while (<IN>) {
		next if /^#/;
		if (/(\S+)\s*=\s*(\S+)/) {
			my ($software_name,$software_address) = ($1,$2);
			$config_p->{$software_name} = $software_address;
			if (! -e $software_address){
				warn "Non-exist:  $software_name  $software_address\n"; 
				$error_status = 1;
			}
		}
	}
	close IN;
	die "\nExit due to error of software configuration\n" if($error_status);
}


##prepare data for genewise and make the qsub shell
####################################################


sub prepare_genewise{
	my $solar_file = shift;
	my $Gff=shift;
	my %gff;
	read_gff($Gff,\%gff) if($Gff);
	my @corr;

	open IN, "$solar_file" || die "fail $solar_file";
#ENSGALP00000000003-D1   77      1       76      +       Scaffold151     6292079 3074470 3075302 2       98.70   1,42;37,76;
	while (<IN>) {
		s/^\s+//;
		my @t = split /\s+/;
		my $query = $t[0];
		my $strand = $t[4];
		my ($query_start,$query_end) = ($t[2] < $t[3]) ? ($t[2] , $t[3]) : ($t[3] , $t[2]);
		my $subject = $t[5];
		my ($subject_start,$subject_end) = ($t[7] < $t[8]) ? ($t[7] , $t[8]) : ($t[8] , $t[7]);
		push @corr, [$query,$subject,$query_start,$query_end,$subject_start,$subject_end,"","",$strand]; ## "6:query_seq" "7:subject_fragment"	
	}
	close IN;
	my %fasta;
	&Read_fasta($Qr_file,\%fasta);
	foreach my $p (@corr) {
		my $query_id = $p->[0];
		$query_id =~ s/-D\d+$//;
		if (exists $fasta{$query_id}) {
			$p->[6] = $fasta{$query_id}{seq};
		}
	}
	undef %fasta;
	my %fasta;
	&Read_fasta($Db_file,\%fasta);
	foreach my $p (@corr) {
		if (exists $fasta{$p->[1]}) {
			my $parent_id=$p->[0];
			$parent_id=$1 if($parent_id =~ /(\S+)-D\d+/);
			#print "$parent_id\n";
			my @a=sort {$a->[3] <=> $b->[3]} @{$gff{$parent_id}} if(exists $gff{$parent_id});
			my ($query_head_gap,$query_tail_gap)=(0,0);
			($query_head_gap,$query_tail_gap)=call($p->[2],$p->[3],\@a) if(scalar @a > 0);#################
			if ($query_head_gap < 0 || $query_tail_gap < 0){
				die "Please check the length of .pep and CDS for $p->[0]\n";
			}
			my $seq = $fasta{$p->[1]}{seq};
			my $len = $fasta{$p->[1]}{len};
			#print  join("\t",$p->[0],$p->[1],$len,$p->[2],$p->[3],$p->[4],$p->[5],$p->[8],$query_head_gap,$query_tail_gap,$a[0]->[6]);
			$p->[4] -= ($Param->{'filter-solar'}{extent}+$query_head_gap) if($p->[8] eq '+'); 
			$p->[4] -= ($Param->{'filter-solar'}{extent}+$query_tail_gap) if($p->[8] eq '-');
			$p->[4] = 1 if($p->[4] < 1);
			$p->[5] += ($Param->{'filter-solar'}{extent}+$query_tail_gap) if($p->[8] eq '+');
			$p->[5] += ($Param->{'filter-solar'}{extent}+$query_head_gap) if($p->[8] eq '-');
			$p->[5] = $len if($p->[5] > $len);
			#print "\t$p->[4]\t$p->[5]\n";
			$p->[7] = substr($seq,$p->[4] - 1, $p->[5] - $p->[4] + 1); 
		}
	}
	undef %fasta;
	mkdir "$genewise_dir" unless (-d "$genewise_dir");
	my $parentdir="00";
	my $subdir = "000";
	my $parentloop=0;
	my $loop = 0;
	my $cmd;
	my $opt_genewise = join(" ",%{$Param->{genewise}});
	foreach my $p (@corr) {
		if($loop % 100 == 0){
			if($parentloop % 100 ==0){
				$parentdir++;
				mkdir ("$genewise_dir/$parentdir");
				$subdir="000";
			}
			$subdir++;
			mkdir("$genewise_dir/$parentdir/$subdir");
			$parentloop++;
		}
		
		my $qr_file = "$genewise_dir/$parentdir/$subdir/$p->[0].fa";
		my $db_file = "$genewise_dir/$parentdir/$subdir/$p->[0]_$p->[1]_$p->[4]_$p->[5].fa";
		my $rs_file = "$genewise_dir/$parentdir/$subdir/$p->[0]_$p->[1]_$p->[4]_$p->[5].genewise";
		
		open OUT, ">$qr_file" || die "fail creat $qr_file";
		print OUT ">$p->[0]\n$p->[6]\n";
		close OUT;
		open OUT, ">$db_file" || die "fail creat $db_file";
		print OUT ">$p->[1]_$p->[4]_$p->[5]\n$p->[7]\n";
		close OUT;

		my $choose_strand = ($p->[8] eq '+') ? "-tfor" : "-trev";
		$cmd .= "$config{genewise} $choose_strand $opt_genewise $qr_file $db_file > $rs_file 2> /dev/null\n";
		$loop++;
	}
	undef @corr;

	open OUT, ">$genewise_shell_file" || die "fail creat $genewise_shell_file";
	print OUT $cmd;
	close OUT;
}

sub call{
	my ($gap_head,$gap_tail,$array)=@_;
	$gap_head--;
	$gap_head=$gap_head*3;
	$gap_tail=$gap_tail*3;
	my ($head_gap,$tail_gap,$cds_len)=(0,0,0);
	if($array->[0]->[6] eq '+'){
		for(@$array){
			$cds_len+=($_->[4]-$_->[3]+1);
			if($cds_len > $gap_head && $head_gap == 0){
				$head_gap=($_->[3]+($gap_head-$cds_len+($_->[4]-$_->[3]+1)));
			}
			if($cds_len >= $gap_tail && $tail_gap == 0){
				$tail_gap=($_->[3]+($gap_tail-$cds_len+($_->[4]-$_->[3]+1)-1));
			}
		}
		($head_gap,$tail_gap)=($head_gap-$array->[0]->[3],$array->[-1]->[4]-$tail_gap);
		return ($head_gap,$tail_gap);
	}else{
		for(reverse @$array){
			$cds_len+=($_->[4]-$_->[3]+1);
			if($cds_len > $gap_head && $head_gap == 0){
				$head_gap=($_->[3]+($cds_len-$gap_head)-1);
			}
			if($cds_len >= $gap_tail && $tail_gap == 0){
				$tail_gap=($_->[3]+$cds_len-$gap_tail);
			}
		}
		($head_gap,$tail_gap)=($array->[-1]->[4]-$head_gap,$tail_gap-$array->[0]->[3]);
		return ($head_gap,$tail_gap);
	}
}

sub read_gff{
	my ($file,$hash)=@_;
	open IN,$file or die $!;
	while(<IN>){
		next if /^#/;
		chomp;
		my @a=split /\t+/;
		@a[3,4]=@a[4,3] if($a[3] > $a[4]);
		if($a[2] eq 'CDS' && $a[8] =~ /Parent=([^;\s]+)/){
			push @{$$hash{$1}},[@a];
		}
	}
	close IN;
}

##conjoin the overlapped fragments, and caculate the redundant size
##usage: conjoin_fragment(\@pos);
##		 my ($all_size,$pure_size,$redunt_size) = conjoin_fragment(\@pos);
##Alert: changing the pointer's value can cause serious confusion.
sub Conjoin_fragment{
	my $pos_p = shift; ##point to the two dimension input array
	my $distance = shift || 0;
	my $new_p = [];         ##point to the two demension result array
	
	my ($all_size, $pure_size, $redunt_size) = (0,0,0); 
	
	return (0,0,0) unless(@$pos_p);

	foreach my $p (@$pos_p) {
			($p->[0],$p->[1]) = ($p->[0] <= $p->[1]) ? ($p->[0],$p->[1]) : ($p->[1],$p->[0]);
			$all_size += abs($p->[0] - $p->[1]) + 1;
	}
	
	@$pos_p = sort {$a->[0] <=>$b->[0]} @$pos_p;
	push @$new_p, (shift @$pos_p);
	
	foreach my $p (@$pos_p) {
			if ( ($p->[0] - $new_p->[-1][1]) <= $distance ) { # conjoin two neigbor fragements when their distance lower than 10bp
					if ($new_p->[-1][1] < $p->[1]) {
							$new_p->[-1][1] = $p->[1]; 
					}
					
			}else{  ## not conjoin
					push @$new_p, $p;
			}
	}
	@$pos_p = @$new_p;

	foreach my $p (@$pos_p) {
			$pure_size += abs($p->[0] - $p->[1]) + 1;
	}
	
	$redunt_size = $all_size - $pure_size;
	return ($pure_size);
}

