#!/usr/bin/perl -w
use strict;
use File::Basename;
use Cwd 'abs_path';
use FindBin qw($Bin $Script);
unless (@ARGV == 6) {
	die <<"Usage End.";
Description:
    This script is used to ...

Usage: perl $0 origin.gff predict.gff predict.genewise genome.fa out_dir/ qsub_memory(Gb)

Example:

Usage End.
}
my ($origin_gff, $predict_gff, $predict_genewise, $genome_file, $out_dir, $qsub_mem) = @ARGV;
mkdir $out_dir unless -e $out_dir;
foreach my $p (\$origin_gff, \$predict_gff, \$predict_genewise, \$genome_file, \$out_dir) {
	$$p = abs_path($$p);
}

## script needed.
my $getGene = "$Bin/getGene.pl";
my $cds2aa = "$Bin/cds2aa.pl";
my $check_orf_for_cds = "$Bin/check_orf_for_cds.pl";
my $bad_orf_filter = "$Bin/bad_orf_filter.pl";
my $retrotransposed_filter = "$Bin/retrotransposed_filter.pl";
my $gff2pos = "$Bin/gff2pos.pl";
my $findOverlap = "$Bin/findOverlap_new.pl";
my $merge_cds_overlap = "$Bin/merge_cds_overlap.pl";
foreach my $script ($getGene, $cds2aa, $check_orf_for_cds, $bad_orf_filter, $retrotransposed_filter, $gff2pos, $findOverlap, $merge_cds_overlap) {
	die "$script does not exist!" unless -e $script;
}

my $sp = basename($predict_gff);
my $sh_file = "$out_dir/$sp.sh";
open SH, ">$sh_file";
print SH <<shell;
date
perl $getGene $predict_gff $genome_file >$out_dir/$sp.cds
perl $check_orf_for_cds $out_dir/$sp.cds >$out_dir/$sp.cds.check
rm $out_dir/$sp.cds
perl $gff2pos $predict_gff 2 >$out_dir/$sp.pos 
perl $findOverlap $out_dir/$sp.pos $out_dir/$sp.pos >$out_dir/$sp.pos.overlap
perl $merge_cds_overlap $out_dir/$sp.pos.overlap $predict_gff $predict_genewise >$out_dir/$sp.pos.overlap.merge.gff
perl $gff2pos $out_dir/$sp.pos.overlap.merge.gff 2 >$out_dir/$sp.pos.overlap.merge.gff.pos
perl $findOverlap $out_dir/$sp.pos.overlap.merge.gff.pos $out_dir/$sp.pos.overlap.merge.gff.pos >$out_dir/$sp.pos.overlap.merge.gff.pos.overlap
perl $merge_cds_overlap $out_dir/$sp.pos.overlap.merge.gff.pos.overlap $predict_gff $predict_genewise >$out_dir/$sp.pos.overlap.merge.gff.pos.overlap.merge.gff
rm $out_dir/$sp.pos $out_dir/$sp.pos.overlap $out_dir/$sp.pos.overlap.merge.gff $out_dir/$sp.pos.overlap.merge.gff.pos $out_dir/$sp.pos.overlap.merge.gff.pos.overlap 
mv $out_dir/$sp.pos.overlap.merge.gff.pos.overlap.merge.gff $out_dir/$sp.nr.gff
perl $getGene $out_dir/$sp.nr.gff $genome_file >$out_dir/$sp.nr.cds
perl $cds2aa $out_dir/$sp.nr.cds >$out_dir/$sp.nr.pep
date
shell
close SH;

&call_qsub($qsub_mem, $sh_file);

##########################################################################################
##################################### subroutine #########################################
##########################################################################################
sub call_qsub {
	my ($mem, $sh_file) = @_;
	system "qsub -S /bin/sh -cwd -l vf=${mem}g  -q ngb.q -P ngb_un  $sh_file";
}

sub getGffFile {
	my ($in_dir, $ref) = @_;
	opendir DH, $in_dir;
	while (my $file = readdir DH) {
		next unless $file =~ /\.gff$/;
		my $sp = (split /\./, $file)[0];
		my $in_file = "$in_dir/$file";
		$ref->{$sp} = $in_file;
	}
	closedir DH;
}

sub getGenewiseFile {
	my ($in_dir, $ref1, $ref2) = @_;
	opendir DH, $in_dir;
	while (my $file = readdir DH) {
		next unless $file =~ /\.genewise$/;
		my $sp = (split /\./, $file)[0];
		my $in_file = "$in_dir/$file";
		$ref1->{$sp} = $in_file;
		push @$ref2, $in_file;
	}
	closedir DH;
}
