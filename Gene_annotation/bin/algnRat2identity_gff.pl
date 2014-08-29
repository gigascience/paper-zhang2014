#!/usr/bin/perl

if (@ARGV != 2)
{
	print "perl $0 <ident.list.filter> <.genewise.gff>\n";
	exit;
}

use strict;

my $tab = shift;
my $gff = shift;

my %gn_sm;
&read_tab($tab,\%gn_sm); # sub 1

&gff_alignedRate_2_identity($gff,\%gn_sm); # sub 2



## sub 1
##
sub read_tab
{
	my $file = shift;
	my $hsp  = shift;

	open IN,$file or die;
	while (<IN>)
	{
		my @c = split;
		$hsp->{$c[0]} = sprintf "%.2f", $c[7];
	}
	close IN;
}


## sub 2
##
sub gff_alignedRate_2_identity
{
	my $file = shift;
	my $hsp  = shift;

	open IN,$file or die;
	while (<IN>)
	{
		my @c = split;
		if ($c[2] eq "mRNA" and $c[8] =~ /ID=([^;]+);/)
		{
			
			if (exists $hsp->{$1})
			{
				$c[5] = $hsp->{$1};
				print join ("\t",@c);
				print "\n";
			}
		}elsif ($c[2] eq "CDS" and $c[8] =~ /Parent=([^;]+);/)
		{
			print if (exists $hsp->{$1});
		}
	}
	close IN;
}
