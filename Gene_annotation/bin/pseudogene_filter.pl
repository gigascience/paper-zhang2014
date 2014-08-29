#!/usr/bin/perl

#2011.09.29

if (@ARGV != 2)
{
	print "perl $0 <.gff> <.cds>\n";
	exit;
}

use strict;

my $gff = shift;
my $cds = shift;

my %stopCondon;
&read_cds($cds,\%stopCondon); # sub 1

&filter_frameShift_innerStopCodon($gff,\%stopCondon); # sub 2


## sub 1
##
sub read_cds
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die;
	$/ = ">";
	<IN>;
	$/ = "\n";
	while (<IN>)
	{
		my $id = (split)[0];
		$/ = ">";
		my $seq = <IN>;
		$seq =~ s/\>$//;
		$seq =~ s/\s+//g;
		$/ = "\n";

		$seq = uc($seq);
		my $len=length($seq);
		my  $mid = 0;
		for (my $i=3; $i<$len-3; $i+=3)
		{
			my $codon=substr($seq,$i,3);
			$mid++ if($codon eq 'TGA' || $codon eq 'TAG' || $codon eq 'TAA');
		}
		$hshp->{$id} = $mid;
	}
	close IN;
}


## sub 2
##
sub filter_frameShift_innerStopCodon
{
	my $file = shift;
	my $hshp = shift;
	
	my @fam = ();
	my $flag = 1;
	open IN,$file or die;
	my  $ln = <IN>;
	push @fam,$ln;
	while (<IN>)
	{
		my @c = split;
		if ($c[2] eq "mRNA")
		{
			chomp $fam[0];
			$fam[0] =~ /ID=([^;]+);Shift=(\d+);/;
			$fam[0] .= "MidStop=$hshp->{$1};\n";
			my $exon_n = scalar @fam - $2;
			if ($hshp->{$1} + $2 <= 2)
			{
#				print join ("",@fam);
#			}elsif ($hshp->{$1} + $2 <= 8 and $exon_n > 1)
#			{
				 print join ("",@fam);
			}
			else
			{
				print STDERR join ("",@fam);
			}

			@fam = ();
			push @fam,$_;
		}else
		{
			push @fam,$_;
		}
	}
	close IN;

	$fam[0] =~ /ID=([^;]+);Shift=(\d+);/;
	my $pseudo = $hshp->{$1} + $2;
	chomp $fam[0];
	$fam[0] .= "MidStop=$hshp->{$1};\n";
	my $exon_n = scalar @fam - $2;
#	if ($hshp->{$1} + $2 <= 3)
	if ( $pseudo <= 2)
	{
#		print join ("",@fam);
#	}elsif ($hshp->{$1} + $2 <= 8 and $exon_n > 1)
#	{
#		print join ("",@fam);
	}else
	{
		 print STDERR join ("",@fam);
	}
}

