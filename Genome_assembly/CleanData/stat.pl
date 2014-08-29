#!/usr/bin/perl
use strict;

die "Usage:$0 <lib.lst> <*_1.fq.reads.stat> <*_1.fq.clean.dup.stat> \n" if @ARGV<3;

my $lib_lst =shift;
my $reads_stat =shift;
my $dup_stat =shift;
my $parameter =shift;

my %Lib;
open IN,$lib_lst or die "$!";
while(<IN>){
	if (/(\S+)\s+(\d+)/){
		$Lib{$1}=$2;
	}else{
		next;
	}
}
close IN;

my @Stat;
open IN,$reads_stat or die "$!";
while(<IN>){
	next if !/^\d/;
	chomp;
	@Stat = split(/\t/);
}
close IN;

my $Duplicate;
my $Usable_reads = 0;
open IN,$dup_stat or die "$!";
while(<IN>){
	if (/Duplicate_reads:(\d+)/){
		$Duplicate = $1;
	}elsif(/Clean_reads:(\d+)/){
		$Usable_reads = $1*2;
	}else{
		next;
	}
}
close IN;

if ( $Usable_reads == 0 ){
	die "Format error: $dup_stat\n";
}

my ($lib,$lane);
if ($reads_stat =~ /(\d+\_[^_]+\_FC[^_]+_L\d+)_([^_]+)_1\.fq\S{0,3}.reads.stat/){
	$lib = $2;
	$lane = $1."_".$2;
}else{
	die "$!";
}

my $Insertsize = $Lib{$lib};
my $Read_len = $Stat[1];
my $Raw_reads = $Stat[0]*2 ;
my $Raw_bases = $Stat[2];
my $GC = $Stat[5]."_".$Stat[6];
my $Q20 = $Stat[3]."_".$Stat[4];
my $Ns_num = $Stat[7]/$Raw_reads * 2 * 100;
#print "$Ns_num\n";
my $Low_qual = $Stat[8]/$Raw_reads * 2 * 100;
my $Adapter = $Stat[9]/$Raw_reads * 2 * 100;
my $Small = $Stat[10]/$Raw_reads * 2 * 100;
my $Dup = $Duplicate/$Raw_reads * 2 * 100;
my $Usable_len = $Stat[11]."_".$Stat[12];
my $Usable_bases = $Usable_reads * ($Stat[11] + $Stat[12])/2;
$Raw_reads = $Raw_reads / 1000000;
$Raw_bases = $Raw_bases / 1000000;
$Usable_reads = $Usable_reads / 1000000;
$Usable_bases = $Usable_bases / 1000000;

print join("\t",$lib,$lane,$Insertsize,$Read_len,$GC,$Q20,$Ns_num,$Low_qual,$Adapter,$Small,$Dup,$Raw_reads,$Raw_bases,$Usable_len,$Usable_reads,$Usable_bases,$parameter)."\n";
