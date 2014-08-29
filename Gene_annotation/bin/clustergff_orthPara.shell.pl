#!/usr/bin/perl
=head1 Name
 
 clustergff.shell.pl

=head1 Description

 pipeline to do gene cluster.

=head1 Version

  Author: Shiping Liu
  Modified: Bo Li

=head1 Usage

 perl clustergff.shell.pl [options] <mRNA.gff> <orthlog.gff> <paralog.gff>
 
 --cpu <int>          set the cpu number to use in parallel, default=5
 --run <str>          set the parallel type, qsub, or multi, default=multi
 --cutoff <int>       set overlap cutoff, default = 100
 --verbose            output verbose information to screen,default no
 --help               output help information to screen,default no

=cut



use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw(dirname basename);
use FindBin qw($Bin $Script);

my ($run,$cpu,$cutoff,$verbose,$help);
GetOptions(
	"cpu:i"=>\$cpu,
	"run:s"=>\$run,
        "cutoff:i"=>\$cutoff,
	"verbose!"=>\$verbose,
	"help!"=>\$help
);

$cpu ||= 5;
$cutoff ||= 100;
$run ||= "multi";

die `pod2text $0` if (@ARGV == 0 || $help);


my $file = shift;
my $orth = shift;
my $para = shift;

my $file2= "$file.temp.gff";

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

my $basename = basename ($file2, '.gff');
my $dirname = dirname ($file2); 

#`perl $Bin/scores_gff2.pl $file2 $taxon > $dirname/$basename.score`;
`perl $Bin/scores_gff_para.pl $para > $dirname/$basename.score`;
`perl $Bin/scores_gff_orth.pl $orth >> $dirname/$basename.score `;
`perl $Bin/cluster/run_cluster_lsp.pl  $file2 $dirname/$basename.score $run $cutoff $cpu`;

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
`rm -rf $file.temp.*` unless ($verbose);
