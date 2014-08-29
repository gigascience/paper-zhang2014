#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin $Script);

die "Usage: <gff_dir> <annotation> <out_dir>!\n" unless @ARGV == 3;
my $gff_dir = shift;
my $annotation = shift;
my $out_dir = shift;

mkdir $out_dir unless -e $out_dir;

my %hash;
opendir GD, $gff_dir;
while (my $file = readdir GD) {
	my $sp;
	if ($file =~ /\.gff$/) {
		$sp = (split /\./, $file)[0];
		$hash{$sp}{"gff"} = "$gff_dir/$file";
	} elsif ($file =~ /\.cds\.check$/) {
		$sp = (split /\./, $file)[0];
		$hash{$sp}{"check"} = "$gff_dir/$file";
	}
}
closedir GD;

my $improve = "$Bin/gene_improve_gff.pl";
foreach my $sp (keys %hash) {
	open SH, " >$out_dir/$sp.gff.sh";
	print SH "date\n";
	print SH "perl $improve $hash{$sp}{gff} $hash{$sp}{check} $gff_dir/blastToPEP/$sp/$sp.m8.best $annotation >$out_dir/$sp.gff\n";
	print SH "date\n";
	close SH;
	#`sh $out_dir/$sp.gff.sh`;
	`qsub -S /bin/sh -cwd -l vf=0.01G -q ngb.q -P ngb_un $out_dir/$sp.gff.sh`;
}



