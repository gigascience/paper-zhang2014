#!/usr/bin/perl
use strict;

die "$0 <pep.len> <solar_file> <.ortholog>\n" if(@ARGV != 3);

my $pep_len    = shift;
my $solar_file   = shift;
my $ortholog = shift; ##to both

my %Len;
&Read_tab($pep_len,\%Len); # sub 1

my %align_ratio;
&caculate_align_rate($solar_file,\%align_ratio,\%Len); # sub 2

&align_rate_each_ortholog($ortholog,\%align_ratio); # sub 3



## sub 1
##
sub Read_tab
{
	my $file=shift;
	my $hash_p=shift;
	
	open(IN, $file) || die ("can not open $file\n");
	while (<IN>) 
	{
		my ($name,$size) = (split)[0,1];
		
		if (exists $hash_p->{$name}) {
			warn "name $name is not uniq";
		}

		$hash_p->{$name} = $size;
	}
	close IN;
}


## sub 2
##
sub caculate_align_rate
{
	my $file = shift;
	my $hshp = shift;
	my $hsp2 = shift;

	open IN,$file or die "Fail to open $file";
	while (<IN>)
	{
		my @t = split /\t/;	
		my $query_align = 0;
        	my $target_align = 0;
		while ($t[11] =~ /(\d+),(\d+);/g) 
		{
                	$query_align += abs($2 - $1) + 1;
        	}
		while ($t[12] =~ /(\d+),(\d+);/g)
		{
			$target_align += abs($2 - $1) + 1;
		}
		$hshp->{$t[0]}{$t[5]} = $query_align / $hsp2->{$t[0]};
		$hshp->{$t[5]}{$t[0]} = $target_align / $hsp2->{$t[5]};
	}
	close IN;
}


## sub 3
##
sub align_rate_each_ortholog
{
	my $file = shift;
	my $hshp = shift;

	my $out = "ID1\tPerc_of_syn1\tExonNum1\tPepLen1\tID2\tPerc_of_syn2\tExonNum2\tPepLen2\tHgID\tExonNum\tPepLen\tAlignR1_ID1\tAlignR1_hg\tAlignR2_ID2\tAlignR2_hg\tBestRef\n";
	open IN,$file or die;
	<IN>;
	while (<IN>)
	{
		my @g = split /\t/,$_;
		$hshp->{$g[8]}{$g[0]} = "NA" if (!exists $hshp->{$g[8]}{$g[0]});
		$hshp->{$g[0]}{$g[8]} = "NA" if (!exists $hshp->{$g[0]}{$g[8]});
		$hshp->{$g[8]}{$g[4]} = "NA" if (!exists $hshp->{$g[8]}{$g[4]});
		$hshp->{$g[4]}{$g[8]} = "NA" if (!exists $hshp->{$g[4]}{$g[8]});
		if ($hshp->{$g[8]}{$g[0]} > $hshp->{$g[8]}{$g[4]})
		{
			pop @g;
			$out .= (join "\t",@g)."\t$hshp->{$g[0]}{$g[8]}\t$hshp->{$g[8]}{$g[0]}\t$hshp->{$g[4]}{$g[8]}\t$hshp->{$g[8]}{$g[4]}\t$g[0]\n";
		}else
		{
			pop @g;
			$out .= (join "\t",@g)."\t$hshp->{$g[0]}{$g[8]}\t$hshp->{$g[8]}{$g[0]}\t$hshp->{$g[4]}{$g[8]}\t$hshp->{$g[8]}{$g[4]}\t$g[4]\n";
		}
	}
	close IN;
	
	print $out;
}
