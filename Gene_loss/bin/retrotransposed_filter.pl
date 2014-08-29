#!/usr/bin/perl -w
use strict;
die "Usage: <genewise.gff> <origin.gff> <cds.check>\n" unless @ARGV == 3;
my $genewise_gff_file = shift;
my $origin_gff_file = shift;
my $cds_check_file = shift;

## get the total exon number of each gene model.
my (%origin_exon_num, %genewise_exon_num);
&exon_parser($origin_gff_file, \%origin_exon_num);
&exon_parser($genewise_gff_file, \%genewise_exon_num);

## read the whole genewise.gff into memory and get the total cds length of each predicted gene model.
my (%genewise_gff, %cdsLength);
&dealGff($genewise_gff_file, \%genewise_gff, \%cdsLength);
my %frameShift;
&countFrameshift($genewise_gff_file, \%frameShift);
my %preStop;
&countPreStopCodon($cds_check_file, \%preStop);


## Filter predicted gene models with 
foreach my $id (sort keys %genewise_exon_num) {
	my $g_exon_num = $genewise_exon_num{$id};
	die "$id" unless $id =~ /^(\S+?)-D\d+$/;
	my $ori_id = $1;
	my $q_exon_num = $origin_exon_num{$ori_id};

	## filter putative processed pseudogenes.
	next if $q_exon_num > 1 && $g_exon_num == 1; 
	
	## filter genes whose total cds length is not the integral multiple of 3.
	my $cds_length = $cdsLength{$id};
	if ($cds_length % 3) {
		print STDERR "The total cds length of $id is $cds_length, it is not the integral multiple of 3.";
		next;
	}
	
	## filter genes whose total cds length is too short, >=300bp for single cds genes, >=150 for multiple cds genes.
	if ($g_exon_num == 1) {
		next unless $cds_length >= 300;
	} elsif ($g_exon_num > 1) {
		next unless $cds_length >= 150;
	} else {
		die;
	}

	## filter the single CDS genes with premature stop codon or frameshift.
	if ($g_exon_num == 1) {
		next if $preStop{$id} + $frameShift{$id} > 0;
	}

	print $genewise_gff{$id};
}


##########################################################################################
##################################### subroutine #########################################
##########################################################################################
sub exon_parser {
	my ($in_file, $ref) = @_;
	my %cdsPos;
	my %geneStrand;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		my @info = split /\s+/;
		next unless $info[2] eq "CDS";
		die unless $info[8] =~ /Parent=(\S+?);/;
		my $gene = $1;
		($info[3], $info[4]) = sort {$a <=> $b} ($info[3], $info[4]);
		push @{$cdsPos{$gene}}, [$info[3], $info[4]];
		$geneStrand{$gene} = $info[6];
	}
	close IN;

	##sort cds
	foreach my $gene (keys %cdsPos) {
		my %p_to_bg;
		foreach my $p (@{$cdsPos{$gene}}) {
			$p_to_bg{$p} = $p->[0];
		}
		@{$cdsPos{$gene}} = sort {$p_to_bg{$a} <=> $p_to_bg{$b}} @{$cdsPos{$gene}} if $geneStrand{$gene} eq "+";
		@{$cdsPos{$gene}} = sort {$p_to_bg{$b} <=> $p_to_bg{$a}} @{$cdsPos{$gene}} if $geneStrand{$gene} eq "-";
	}
	foreach my $gene (keys %cdsPos) {
		my $exon_num = @{$cdsPos{$gene}};
		my $exon_count = 1;
		for (my $i = 0; $i < @{$cdsPos{$gene}}-1; $i ++) {
			my $p1 = $cdsPos{$gene}->[$i];
			my $p2 = $cdsPos{$gene}->[$i+1];

			my ($bg1, $ed1) = @$p1;
			my ($bg2, $ed2) = @$p2;
			my ($led, $nbg) = (sort {$a <=> $b} ($bg1, $ed1, $bg2, $ed2))[1, 2];
			if ($nbg - $led > 6) {
				$exon_count ++;
			}
		}
		$ref->{$gene} = $exon_count;
	}
}

sub dealGff {
	my ($in_file, $ref1, $ref2) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		my @info = split /\s+/;
		my $id;
		die unless $info[8] =~ /^ID=\S+?;/ || $info[8] =~ /^Parent=\S+?;/;
		if ($info[8] =~ /^ID=(\S+?);/) {
			$id = $1;
		} elsif ($info[8] =~ /^Parent=(\S+?);/) {
			$id = $1;
			$ref2->{$id} += $info[4] - $info[3] + 1;
		} else {
			die;
		}
		$ref1->{$id} .= $_;
	}
	close IN;
}

sub countFrameshift {
	my ($in_file, $ref) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		my @info = split /\s+/;
		next unless $info[2] eq "mRNA";
		die unless $info[8] =~ /^ID=(\S+?);/;
		my $id = $1;
		die unless $info[8] =~ /;Shift=(\d+?);/;
		my $fs = $1;
		$ref->{$id} = $fs;
	}
	close IN;
}

sub countPreStopCodon {
	my ($in_file, $ref) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		next if /^#/;
		my @info = split /\s+/; 
		$ref->{$info[0]} = $info[3];
	}
	close IN;
}
