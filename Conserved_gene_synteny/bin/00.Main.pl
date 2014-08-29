#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);

die "Usage: perl $0 <species.list> <ortholog.indir> <gff.dir> <species.list.div>\n" unless @ARGV == 4;

my ($gffDir, $div) = @ARGV[2,3];

my @species;
open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	push @species,(split /\s+/,$_)[0];
}
close IN;

my @tmp;
foreach my $spe (sort @species) {
	if (@tmp > 0) {
		foreach my $ele (@tmp) {
			my $mix = join "_",$spe,$ele;
			open (OT,">$ARGV[1]/$mix.sh") or die $!;
			print OT "date\n";
			print OT "perl $Bin/01.Call.OSBs.pl $ARGV[1]/$mix/2_ortholog $gffDir 0.01 $ARGV[1]/$mix/3_syntenic $spe $ele $div \n";
			print OT "date\n";
			close OT;
			system "sh $ARGV[1]/$mix.sh";
		}
	}
	push @tmp,$spe;
}
