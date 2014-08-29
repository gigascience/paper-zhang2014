#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <2species.ort> <cutoff: e.g. 5> <extended.gene number: e.g. 2> <absolute difference: e.g. 5> <ref.gff> <target.gff> <div.file>\n " unless @ARGV == 8;

my ($file,$cutoff,$stretch,$dif,$refgff,$targff,$div) = @ARGV;
my ($ref_num,$tar_num,$syntenic,$ortholog_num) = (0,0,0,0);
my $aa = (split /\./,(split /\//,$refgff)[-1])[0];
my $bb = (split /\./,(split /\//,$targff)[-1])[0];

$ref_num = &dealGff($refgff);
$tar_num = &dealGff($targff);

my $divtime;
open (IN,$div) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	next unless ($info[0] eq $aa && $info[1] eq $bb);
	$divtime = $info[2];
}
close IN;

open (IN,$file) or die $!;

my @lines;
my $first = <IN>;   chomp $first;	my @xixi = split /\s+/,$first;	$ortholog_num += 1 if ($xixi[7] ne "NA");
push @lines,$first;

while (1) {
	my @info = split /\s+/,$first;
	my $line1 = <IN>;
	last unless $line1;
	chomp $line1;
	my @info1 = split /\s+/,$line1;

	$ortholog_num += 1 if ($info1[7] ne "NA");
	
	if ($info1[1] eq $info[1]) {
	
	} else {
		&dealBlock(\@lines) if (@lines >=$cutoff);
		@lines = ();
	}
	$first = $line1;
	push @lines,$first;
}
&dealBlock(\@lines) if (@lines >=$cutoff);
close IN;

my $per1 = sprintf "%.2f",$syntenic/$ref_num*100;
my $per2 = sprintf "%.2f",$syntenic/$tar_num*100;
my $per3 = sprintf "%.2f",$ortholog_num/$ref_num*100;
my $per4 = sprintf "%.2f",$ortholog_num/$tar_num*100;

print "$syntenic\t$ref_num\t$per1\t$tar_num\t$per2\t$ortholog_num\t$per3\t$per4\t$divtime\t$ARGV[7]\n";

################    SUBROUTINE  ####################

sub dealBlock {
	my @block = @{$_[0]};
	my %hash;
	foreach my $line (@block) {
		chomp $line;
		my @ele = split /\s+/,$line;

#		$ref_num ++;	#Total number of ref genes;
#		$tar_num ++ if ($ele[7] ne "NA");	#Total number of target genes;

		next if ($ele[7] eq "NA");
		push @{$hash{$ele[7]}},[$ele[2],$ele[8],$ele[1]];
	}
	
	foreach my $sca (sort keys %hash) {
		next unless (@{$hash{$sca}} >= $cutoff);
		
		my ($order_ref,$order_ort,$chr) = @{${$hash{$sca}}[0]};

		my @record;
		push @record, (join "\t",$chr,$order_ref,$sca,$order_ort);

		for (my $i=1;$i<@{$hash{$sca}};$i++) {
			my ($order_next,$ort_next) = @{${$hash{$sca}}[$i]};
			
			my $dis = abs($order_next-$order_ref);
			my $linearDis = abs ($ort_next-$order_ort);
			if ($dis <= $stretch && $linearDis <= $dif) {
			
			} else {
				if (@record >=$cutoff) {
					$syntenic += scalar(@record);
				}
				@record = ();
			}
			($order_ref,$order_ort) = ($order_next,$ort_next);
			my $mix = join "\t",$chr,$order_ref,$sca,$order_ort;
			push @record,$mix;
		}
		if (@record >=$cutoff) {
			$syntenic += scalar(@record);
		}
	}
}

sub dealGff {
	my ($file) = $_[0];
	my $GeneNo = 0;
	open (IN,$file) or die $!;
	while (<IN>) {
		chomp;
		next if (/^#/);
		my @info = split /\s+/;
		if ($info[2] eq "mRNA") {
			$GeneNo += 1;
		}
	}
	close IN;
	return $GeneNo;
}
