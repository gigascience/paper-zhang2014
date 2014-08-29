#!/usr/bin/perl

#2011.09.20

if (@ARGV != 6)
{
	print "perl $0 <.pep.len> <HUMAN.pep.len> <HUMAN.gene_exonNum.tab> <.exonNum.tab> <.ortholog> <human.ortholog> \n";
	exit;
}

use strict;

my $len_pep  = shift;
my $len_pep2 = shift;
my $exon_num = shift;
my $exon_num2= shift;
my $ortholg  = shift;
my $ortholg2 = shift;

my %pep_len;
&read_protein_length($len_pep,\%pep_len); #sub 1
&read_protein_length($len_pep2,\%pep_len); #sub 1

my %pep_exon_num;
&read_protein_length($exon_num,\%pep_exon_num); # sub 1
&read_protein_length($exon_num2,\%pep_exon_num); # sub 1

my %gal_hg;
&read_ortholog_human_chicken($ortholg2,\%gal_hg); # sub 2

&get_ratio($ortholg,\%pep_len,\%pep_exon_num,\%gal_hg); # sub 3


## sub 1
##
sub read_protein_length
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die "Fail to open $file";
	while (<IN>)
	{
		my ($id,$len) = (split)[0,1];
		$hshp->{$id} = $len;
	}
	close IN;
}


## sub 2
##
sub read_ortholog_human_chicken
{
        my $file = shift;
        my $hshp = shift;

        open IN,$file or die "Fail to open $file";
        while (<IN>)
        {
		my ($id1,$id2) = (split)[0,2];
                $hshp->{$id1} = $id2;
        }
        close IN;

}


## subb 3
##
sub get_ratio
{
	my $file = shift;
	my $hshp1= shift;
	my $hshp2= shift;
	my $hshp3= shift;

	my $out1 = "ID1\tPerc_of_syn1\tExonNum1\tPepLen1\tID2\tPerc_of_syn2\tExonNum2\tPepLen2\tHgID\tExonNum\tPepLen\tBestRef\n";
	$hshp2->{NA} = "NA";
	$hshp1->{NA} = "NA";
	open IN,$file or die;
<IN>;
	while (<IN>)
	{
		chomp;
		my @a = split;
		$hshp3->{$a[0]} = "NA" unless (exists $hshp3->{$a[0]});
	
		my $best;
		my $pepL_ratio = $hshp1->{$a[0]} / $hshp1->{$a[2]};
		my $exon_num_d = $hshp2->{$a[0]} - $hshp2->{$a[2]};
		if (abs($pepL_ratio -1) <= 0.2 and abs($exon_num_d) <= 2)
		{
			$best = $a[0];
		}elsif ($hshp3->{$a[0]} ne "NA")
		{
			my $pepL_ratio1 = $hshp1->{$a[0]} / $hshp1->{$hshp3->{$a[0]}};
			my $pepL_ratio2 = $hshp1->{$a[2]} / $hshp1->{$hshp3->{$a[0]}};
			if (abs($pepL_ratio1 -1) <= abs($pepL_ratio2 -1))
			{
				$best = $a[0];
			}else
			{
				$best = $a[2];
			}
		}else
		{
			$best = "$a[0] $a[2]";
		}

		$out1 .= "$a[0]\t$a[1]\t$hshp2->{$a[0]}\t$hshp1->{$a[0]}\t$a[2]\t$a[3]\t$hshp2->{$a[2]}\t$hshp1->{$a[2]}\t";
		$out1 .= "$hshp3->{$a[0]}\t$hshp2->{$hshp3->{$a[0]}}\t$hshp1->{$hshp3->{$a[0]}}\t$best\n";
	}
	close IN;

	print $out1;
	
}
