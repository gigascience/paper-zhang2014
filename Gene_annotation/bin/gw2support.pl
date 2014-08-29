#!/usr/bin/perl 
use strict;
use warnings;


die "Usage:$0 <genewise> <pep_len>\n\n" if @ARGV<1;

my $genewise=shift;
my $pep=shift;

my %Len;
open IN,$pep or die "$!";
while(<IN>){
	if (/(\S+)\s+(\S+)/){
		$Len{$1}=$2;
	}
}
close IN;

print "#".join("\t",'ID','Pep_len','Start','End','Aligned_len','Pep_pos','Genome_pos')."\n";
open IN,$genewise or die "$!";
$/="//\n";
while(<IN>){
	next if !/^Bits/;
	chomp;
	my $line1=$_;
	my $line2=<IN>;
	chomp $line2;
	my $line3=<IN>;	
	chomp $line3;
	my @l1=split(/\n/,$line1);
	my $len;
	my $pid;
	my $id;
	my $scaffold;
	my ($start,$end);
	if ($l1[1]=~/\S+\s+(\S+)(-D\d+)\s+(\d+)\s+(\d+)\s+(\S+)/){
		$id=$1.$2;
		$pid=$1;
		$scaffold=$5;
		$len=abs($4-$3)+1;
		($start,$end)=($3,$4);
	}else{
		die ;
	}
	my $cover=sprintf("%.2f",$len/$Len{$pid}*100);
	my @l2=split(/\n/,$line2);
	my @sup;
	my @exon;
	my $len2;
	foreach my $l ( @l2 ){
		if ( $l=~/Supporting\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ ){
			push @exon,"$1,$2"; 
			push @sup,"$3,$4";
			$len2+=abs($4-$3)+1;
		}
	}
	print join("\t",$id,$Len{$pid},$start,$end,$len2,join(";",@sup),join(";",@exon))."\n";
}
close IN;
