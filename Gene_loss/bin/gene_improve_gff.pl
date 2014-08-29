#!/usr/bin/perl -w
use strict;

die "Usage: <gff> <check> <tab> <human_ann>!\n" unless @ARGV == 4;
my $gff = shift;
my $check = shift;
my $tab = shift;
my $human_ann = shift;

my %prestop;
open CH, $check;
while (<CH>) {
	chomp;
	next if /^#/;
	my ($gene, $pre) = (split /\s+/)[0,3];
	$prestop{$gene} = $pre;
}
close CH;

my (%best, %hash);
open TA, $tab;
while (<TA>) {
	chomp;
	next if /^#/;
	my ($qid, $sid) = (split /\s+/)[0,6];
	$best{$qid} = $sid;
	$hash{$qid} ++;
	die "$qid\n" unless ($hash{$qid} == 1);
}
close TA;

my (%name, %time);
if ($human_ann =~ /\.gz$/) {
	open HN, "gunzip -c $human_ann |";
} else {
	open HN, $human_ann;
}
my $title = <HN>;
my $idn = $title =~ s/ID/ID/g;
while (<HN>) {
	chomp;
	my @info = (split /\t/);
	if ($idn == 2) {
		$info[2] = "-" unless $info[2];
		$time{$info[1]} ++;
		$name{$info[1]} = $info[2] if ($time{$info[1]} == 1);
	} elsif ($idn == 3) {
		$info[3] = "-" unless $info[3];
		$time{$info[1]} ++;
		$name{$info[1]} = $info[3] if ($time{$info[1]} == 1);
	}
}
close HN;

open GF, $gff;
while (<GF>) {
	chomp;
	my @info = (split /\t/);
	if ($info[2] eq "mRNA") {
		my $gene;
		if ($info[8] =~ /ID=([^;]+)/) {
			$gene = $1;
		}
		my $stop = 0;
		$stop = $prestop{$gene} if $prestop{$gene};
		my $hit = "NA";
		$hit = $best{$gene} if $best{$gene};
		my $na = "-";
		$na = $name{$hit} if $name{$hit};
		print "${_}PreStop=$stop;BestHit=$hit;Name=$na;\n";
	} else {
		print "$_\n";
	}
}
close GF;

