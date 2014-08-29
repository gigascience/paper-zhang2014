#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin $Script);
use Getopt::Long;

die "Usage: <name_table> <gff> <raw_dir> <genome_dir> <out_dir> --q [high|low]!\n" unless @ARGV >= 5;
my $name_table = shift;
my $gff = shift;
my $raw_dir = shift;
my $genome_dir = shift;
my $out_dir = shift;
my $q;
GetOptions(
	"q:s"=>\$q,
);
$q ||= "low";

my $lowQ = "$Bin/dealHomologPredictLQ.pl";
my $highQ = "$Bin/dealHomologPredictHQ.pl";

open NT, $name_table;
while (<NT>) {
	chomp;
	next if /^#/;
	my ($name, $sp) = (split /\s+/)[0,1];
	if ($q eq "high") {
		`perl $highQ $gff $raw_dir/$sp.gff.gz $raw_dir/$sp.genewise.gz $genome_dir/$name/$name.fa $out_dir 0.1`;
	} else {
		die "The value of -q is useless!\n" unless ($q eq "low");
		`perl $lowQ $gff $raw_dir/$sp.gff.gz $raw_dir/$sp.genewise.gz $genome_dir/$name/$name.fa $out_dir 0.1`;
	}
}
close NT;

