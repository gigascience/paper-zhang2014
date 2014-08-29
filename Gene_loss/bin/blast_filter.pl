#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my ($blast_result, @fasta, $query_alignRate_cutoff, $subject_alignRate_cutoff, $identity_cutoff, $best);
my ($Verbose,$Help);
GetOptions(
	"i:s"=>\$blast_result,
	"f:s"=>\@fasta,
	"qac:s"=>\$query_alignRate_cutoff,
	"sac:s"=>\$subject_alignRate_cutoff,
	"ic:s"=>\$identity_cutoff,
	"best"=>\$best,
	"help"=>\$Help,
	"verbose"=>\$Verbose,
);
if (!$blast_result || $Help) {
	print <<"Usage End."; 

Description:
    This program is used to convert m8 files (output of blast) to more readable format. 
    Output format: #1.Query_id\t2.Query_length\t3.Query_start\t4.Query_end\t5.Query_alignRate\t6.Strand\t7.Subject_id\t8.Subject_length\t9.Subject_start\t10.Subject_end\t11.Subject_alignRate\t12.Score\t13.Identity

    Version: 2.0  Date: 2012-8-6
    Author:  liqiye <liqiye\@genomics.org.cn>
			
Usage:
    -i <FILE>     blast reuslt(m8 format), gzip file(e.g *.m8.gz) is acceptable [obligatory].
    -f <FILE>     fasta files(may be more than one file) which is used for get the length of each sequence. [optional] 
                  when -f is not set, 5.Query_alignRate or 11.Subject_alignRate is not informative.
    -qac <FLOAT>  query alignRate cutoff [0~1], default=0
    -sac <FLOAT>  subject alignRate cutoff [0~1], default=0
    -ic  <FLOAT>  identity cutoff [0~100], default=0
    -best         just retain the best hit of each query
    -h            output help information to screen

Example:

    ## Output the best hit for each query.
    perl blast_filter.pl -i blast.m8 -f query.fa -f subject.fa -best >blast.m8.best

    ## Output all the hits for each query, and sort by blast score.
    perl blast_filter.pl -i blast.m8 -f query.fa -f subject.fa >blast.m8.tab
	
    ## If you do care the aligning rate of query or subject, but just need the best hit of each query
    perl blast_filter.pl -i blast.m8 -best >blast.m8.best
    perl blast_filter.pl -i blast.m8 -f query.fa -best >blast.m8.best

Usage End.
	
	exit;
}
$query_alignRate_cutoff = defined($query_alignRate_cutoff) ? $query_alignRate_cutoff : 0;
$subject_alignRate_cutoff = defined($subject_alignRate_cutoff) ? $subject_alignRate_cutoff : 0;
$identity_cutoff = defined($identity_cutoff) ? $identity_cutoff : 0;
#################################################################################################################

## restore the IDs in the m8 file, so that I needn't keep all the sequence lengths in the fasta files later.
my %ids;
if ($blast_result =~ /\.gz$/) {
	open IN, "gunzip -c $blast_result | ";
} else {
	open IN, $blast_result;
}
while (<IN>) {
	my @info = split /\s+/;	
	$ids{$info[0]} ++;
	$ids{$info[1]} ++;
}
close IN;

## get sequence lengths for ids present in the m8 file 
my %seqLen;
my $seq_id;
my %seq_id_count;
foreach my $fasta_file (@fasta) {
	if ($fasta_file =~ /\.gz$/) {
		open IN, "gunzip -c $fasta_file | ";
	} else {
		open IN, $fasta_file;
	}
	while (<IN>) {
		if (/^>/) {
			$seq_id = (split /\s+/)[0];
			$seq_id =~ s/^>//;
			$seq_id_count{$seq_id} ++;
		} else {
			s/\s+//g;
			my $len = length($_);
			$seqLen{$seq_id} += $len unless $seq_id_count{$seq_id} > 1;
		} 
	}
	close IN;
}

## process the m8 file.
my %result;
if ($blast_result =~ /\.gz$/) {
	open IN, "gunzip -c $blast_result | ";
} else {
	open IN, $blast_result;
}
while (<IN>) {
	my @info = split /\s+/;
	my ($q_id, $s_id, $identity, $q_bg, $q_ed, $s_bg, $s_ed, $score) = @info[0,1,2,6,7,8,9,11];
	next if $q_id eq $s_id; ## align to itself.
	my $q_len = $seqLen{$q_id} ? $seqLen{$q_id} : abs($q_ed-$q_bg)+1;
	my $s_len = $seqLen{$s_id} ? $seqLen{$s_id} : abs($s_ed-$s_bg)+1;
	my $q_alignRate = sprintf "%.4f", (abs($q_ed-$q_bg)+1)/$q_len;
	my $s_alignRate = sprintf "%.4f", (abs($s_ed-$s_bg)+1)/$s_len;
	#print "$q_id\t$q_len\t$q_bg\t$q_ed\t#$q_id\t$q_len\t$q_bg\t$q_ed\n";
	next unless $q_alignRate >= $query_alignRate_cutoff && $s_alignRate >= $subject_alignRate_cutoff;
	next unless $identity >= $identity_cutoff;
	my $strand = ($s_ed > $s_bg) ? "+" : "-";
	
	push @{$result{$q_id}}, [$s_id, $identity, $q_len, $q_bg, $q_ed, $q_alignRate, $s_len, $s_bg, $s_ed, $s_alignRate, $strand, $score];

}
close IN;

print "#1.Query_id\t2.Query_length\t3.Query_start\t4.Query_end\t5.Query_alignRate\t6.Strand\t7.Subject_id\t8.Subject_length\t9.Subject_start\t10.Subject_end\t11.Subject_alignRate\t12.Score\t13.Identity\n";
foreach my $q_id (sort keys %result) {
	foreach my $p (sort {$b->[-1] <=> $a->[-1] or $b->[1] <=> $a->[1]} @{$result{$q_id}}) {
		my ($s_id, $identity, $q_len, $q_bg, $q_ed, $q_alignRate, $s_len, $s_bg, $s_ed, $s_alignRate, $strand, $score) = @$p;
		($q_bg, $q_ed) = sort {$a <=> $b} ($q_bg, $q_ed);
		($s_bg, $s_ed) = sort {$a <=> $b} ($s_bg, $s_ed);
		print "$q_id\t$q_len\t$q_bg\t$q_ed\t$q_alignRate\t$strand\t$s_id\t$s_len\t$s_bg\t$s_ed\t$s_alignRate\t$score\t$identity\n";
		last if $best;
	} 
}
