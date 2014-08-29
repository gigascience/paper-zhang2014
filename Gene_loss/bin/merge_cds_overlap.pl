#!/usr/bin/perl -w
use strict;
die "Usage: <cds.overlap> <genewise.gff> <genewise(one or multiple)>\n" unless @ARGV >= 3;
my $cds_overlap_file = shift;
my $genewise_gff_file = shift;
my @genewise_files = @ARGV;

my $overlap_cutoff = 0.3;

## Get the score(Bits) of genewise, it is the major parameter to determine which gene should be kept on a redundant locus.
my %gwScore;
foreach my $genewise_file (@genewise_files) {
	die "$genewise_file: suffix is not .genewise!" unless $genewise_file =~ /\.genewise/;
	&getGenewiseScore($genewise_file, \%gwScore);
}

## Read the whole gff file into memory, and get the total cds length for each predicted gene.
my (%gffFile, %cdsLength);
&dealGff($genewise_gff_file, \%gffFile, \%cdsLength);

## Calculate the cds overlap length of each gene.
my %cdsOverLength;
if ($cds_overlap_file =~ /\.gz$/) {
	open IN, "gunzip -c $cds_overlap_file | ";
} else {
	open IN, $cds_overlap_file;
}
while (<IN>) {
	my @info = split /\s+/; 
	die unless $info[0] =~ /^(\S+)_CDS\d+$/;
	my $q_gene_id = $1;
	my $q_strand = $info[2];
	for (my $i = 7; $i < @info; $i ++) {
		die unless $info[$i] =~ /^(\S+),(\S+),(\S+),(\S+)$/;
		my ($h_cds_id, $h_strand, $h_len, $olp_len) = ($1, $2, $3, $4);
		next unless $q_strand eq $h_strand;
		die unless $h_cds_id =~ /^(\S+)_CDS\d+$/;
		my $h_gene_id = $1;
		$cdsOverLength{$q_gene_id}{$h_gene_id} += $olp_len;
	}
}
close IN;



## Determine which gene model should be kept in a redundant locus. 
my %keptGenes;
foreach my $que_gene_id (keys %cdsOverLength) {
	my $que_cds_len = $cdsLength{$que_gene_id};
	my $que_gw_score = $gwScore{$que_gene_id};
	my @hits;
	foreach my $hit_gene_id (keys %{$cdsOverLength{$que_gene_id}}) {
		my $tot_over_len = $cdsOverLength{$que_gene_id}{$hit_gene_id};
		my $hit_cds_len = $cdsLength{$hit_gene_id};
		my $hit_gw_score = $gwScore{$hit_gene_id};
		my $over_ratio1 = sprintf "%.4f", $tot_over_len/$que_cds_len;
		my $over_ratio2 = sprintf "%.4f", $tot_over_len/$hit_cds_len;
		next unless $over_ratio1 > $overlap_cutoff || $over_ratio2 > $overlap_cutoff;
		push @hits, [$hit_gw_score, $hit_gene_id];
	}
	@hits = sort {$b->[0] <=> $a->[0]} @hits;
	my $kept_gene_id = $hits[0]->[1];
	$keptGenes{$kept_gene_id} ++;
}

foreach my $kept_gene_id (sort keys %keptGenes) {
	die "$kept_gene_id does not exist in $ARGV[1]" unless $gffFile{$kept_gene_id};
	print $gffFile{$kept_gene_id};
}


##########################################################################################
##################################### subroutine #########################################
##########################################################################################
sub getGenewiseScore {
	my ($in_file, $ref) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	$/ = "//\nBits";
	while (<IN>) {
		my @lines = split /\n/;	
		die unless $lines[0] =~ /Query\s+start\s+end\s+Target/;
		my ($score, $id) = (split /\s+/, $lines[1])[0,1];
		$ref->{$id} = $score;
	}
	close IN;
	$/ = "\n";
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
