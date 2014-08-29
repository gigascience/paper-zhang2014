#!/usr/bin/perl -w
use strict;
die "Usage: <cds.fa>\n" unless @ARGV == 1;
my $cds_file = shift;
## the standard codon table.
my %CODE = (
		"standard" =>
		{   
		'GCA' => 'A', 'GCC' => 'A', 'GCG' => 'A', 'GCT' => 'A',                               # Alanine
		'TGC' => 'C', 'TGT' => 'C',                                                           # Cysteine
		'GAC' => 'D', 'GAT' => 'D',                                                           # Aspartic Acid
		'GAA' => 'E', 'GAG' => 'E',                                                           # Glutamic Acid
		'TTC' => 'F', 'TTT' => 'F',                                                           # Phenylalanine
		'GGA' => 'G', 'GGC' => 'G', 'GGG' => 'G', 'GGT' => 'G',                               # Glycine
		'CAC' => 'H', 'CAT' => 'H',                                                           # Histidine
		'ATA' => 'I', 'ATC' => 'I', 'ATT' => 'I',                                             # Isoleucine
		'AAA' => 'K', 'AAG' => 'K',                                                           # Lysine
		'CTA' => 'L', 'CTC' => 'L', 'CTG' => 'L', 'CTT' => 'L', 'TTA' => 'L', 'TTG' => 'L',   # Leucine
		'ATG' => 'M',                                                                         # Methionine
		'AAC' => 'N', 'AAT' => 'N',                                                           # Asparagine
		'CCA' => 'P', 'CCC' => 'P', 'CCG' => 'P', 'CCT' => 'P',                               # Proline
		'CAA' => 'Q', 'CAG' => 'Q',                                                           # Glutamine
		'CGA' => 'R', 'CGC' => 'R', 'CGG' => 'R', 'CGT' => 'R', 'AGA' => 'R', 'AGG' => 'R',   # Arginine
		'TCA' => 'S', 'TCC' => 'S', 'TCG' => 'S', 'TCT' => 'S', 'AGC' => 'S', 'AGT' => 'S',   # Serine
		'ACA' => 'T', 'ACC' => 'T', 'ACG' => 'T', 'ACT' => 'T',                               # Threonine
		'GTA' => 'V', 'GTC' => 'V', 'GTG' => 'V', 'GTT' => 'V',                               # Valine
		'TGG' => 'W',                                                                         # Tryptophan
		'TAC' => 'Y', 'TAT' => 'Y',                                                           # Tyrosine
		'TAA' => 'U', 'TAG' => 'U', 'TGA' => 'U'                                              # Stop
		}
## more translate table could be added here in future
## more translate table could be added here in future
## more translate table could be added here in future
);
#######################################################################################################
#######################################################################################################

my %stopCodon = (
	'TAA' => 'U',
	'TAG' => 'U',
	'TGA' => 'U',
);
if ($cds_file =~ /\.gz$/) {
	open IN, "gunzip -c $cds_file | ";
} else {
	open IN, $cds_file;
}
print "#GeneID\tstartCodon\tstopCodon\tpreStopCodon\ttriple\n";
$/ = ">";
<IN>;
while (<IN>) {
	die unless /(.+)\n/;
	my $id = (split /\s+/, $1)[0];
	s/.+\n//;
	s/\s+|>//g;
	my $len = length($_);
	my $triple = $len % 3;
	$_ = uc($_);
	my $first_codon = substr($_, 0, 3);
	my $is_star = $first_codon eq "ATG" ? 1: 0;
	my $last_codon = substr($_, $len-3, 3);
	my $is_stop = $stopCodon{$last_codon} ? 1 : 0;
	my $middle = 0;
	for (my $i = 0; $i < $len; $i += 3) {
		my $codon = substr($_, $i, 3);
		$middle ++ if $stopCodon{$codon};
	}
	$middle -= $is_stop;
	print "$id\t$is_star\t$is_stop\t$middle\t$triple\n";
}
$/ = "\n";
close IN;
