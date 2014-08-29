#!/usr/bin/perl -w
use strict;
use Cwd 'abs_path';
use FindBin qw($Bin $Script);
use File::Basename;
die "Usage: <2_ortholog dir> <gff dir> <memory(g)> <outdir> <species 1> <species 2> <species.list.div>\n" unless @ARGV == 7;

my $orth_dir = shift;
my $gff_dir = shift;
my $mem = shift;
my $outdir = shift;
my $species1=shift;
my $species2=shift;
my $div= abs_path(shift);


foreach my $p (\$orth_dir, \$outdir, \$gff_dir) {
	$$p = abs_path($$p);
}

my $stat = "$Bin/02.PickOut_SyntenicBlock.Ratio.stat.div.pl";
die "$stat not exist!" unless -e $stat;

mkdir "$outdir" unless -e $outdir;
chdir $outdir;

## get gff file
my %gff;
opendir DH, $gff_dir;
while (my $file = readdir DH) {
	next unless $file =~ /\.gff$/;
	my $in_file = "$gff_dir/$file";
	my $sp = (split /\./, $file)[0];
	$gff{$sp} = $in_file;
}
closedir DH;

## get ort file

open SH, ">run.sh";
print SH "date\n";

opendir DH, $orth_dir;
while (my $file = readdir DH) {
	next unless $file =~ /2species\.ort$/;
	my $in_file = "$orth_dir/$file";
	my $basename = basename($in_file);
	print SH <<cmd;
perl $stat $in_file 5 3 5 $gff{$species1} $gff{$species2} $div ${species1}_vs_${species2}> $basename.per

cmd

}
closedir DH;
print SH "date\n";
close SH;

system "qsub -S /bin/sh -cwd -l vf=${mem}G -q ngb.q -P ngb_un run.sh";

