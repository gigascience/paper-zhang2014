#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use File::Basename qw(dirname basename);
use FindBin qw($Bin $Script);

if (@ARGV < 1 ){
	print "Usage:\n\tperl $0 <gff> [run,qsub/multi,default multi; cutoff,default=1; cpu,default=10; CDS or exon, default=\"CDS\"] <type or genewisefile> [verbose]\n";
	exit;
}

my $file = shift;
my $file2 = "$file.temp.gff";
my $run = shift;
my $cutoff =shift;
my $cpu = shift;
my $cds = shift;
my $type = shift;
my $verbose = shift;

open (IN, $file) || die $!;
open (OUT, ">$file2") || die $!;
while (<IN>){
	chomp;
	next if (/^#/);
	my @c = split /\t/, $_;
	$c[0] = "$c[0]$c[6]";
	my $out = join("\t", @c) . "\n";
	print OUT $out;
}
close IN;
close OUT;

$run ||= "multi";
$cutoff ||=1;
$cpu ||=10;
$cds ||= "CDS";
$type ||= "1";
my $basename = basename ($file2, '.gff');
my $dirname = dirname ($file2); 

if ($type eq "1" ){
#	`perl $Bin/get_CDS_length.pl $file2 $cds >$dirname/$basename.cds.len `;
	`perl $Bin/scores_gff.pl $file2 > $dirname/$basename.score`;
	`perl $Bin/cluster/run_cluster_lsp.pl  $file2 $dirname/$basename.score $run $cutoff $cpu`;
}else{
	`perl /nas/GAG_02/lijianwen/bin/get_genewise_score.pl $type >$dirname/$basename.genewise.score `;
	`perl /nas/GAG_02/lijianwen/bin/run_cluster_lsp.pl $file2 $dirname/$basename.genewise.score $run $cutoff $cpu `;
}

my $file5="$file.uncluster.gff";
open (IN,"$file2.uncluster.gff");
open OUT,">$file5";
while(<IN>){
        chomp;
        my @c = split /\t/, $_;
        $c[0] =~ s/\S$//;
        my $out = join("\t", @c) . "\n";
        print OUT $out;
}
close IN;
close OUT;
`rm $file2.uncluster.gff`;

`mv $file2.dist.hcluster.reference $file.dist.hcluster.reference`;

my $file3 = "$file2.nr.gff";
my $file4 = "$file.nr.gff";
open (IN, $file3) || die $!;
open (OUT, ">$file4") || die $!;
while (<IN>){
	chomp;
	my @c = split /\t/, $_;
	$c[0] =~ s/\S$//;
	my $out = join("\t", @c) . "\n";
	print OUT $out;
}
close IN;
close OUT;

`rm -r $dirname/cluster*` unless ($verbose);
`rm -rf $file.temp.gff*` unless ($verbose);
