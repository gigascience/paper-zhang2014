#!/usr/bin/perl

#2011.0808

if (@ARGV != 4)
{
	print "perl $0 <.CDS.tab1> <.CDS.tab2> <.tab.ovlp> <.GALGA.tab.ovlp>\n";
	exit;
}

use strict;

my $gff1 = shift;
my $gff2 = shift;
my $ovlp_t = shift;
my $ovlp_q = shift;

my %cds_len;
&read_CDStab($gff1,\%cds_len); # sub 1
&read_CDStab($gff2,\%cds_len); # sub 1

my %net_ovlp_t;
&ID_overlap($ovlp_t,\%net_ovlp_t); #sub 2

my %gene_ovlp_q;
&gene_vs_overlap($ovlp_q,\%gene_ovlp_q); #sub 3

#######################################################

my $out;
foreach my $gene( keys %gene_ovlp_q)
{
	my @lines;
	foreach (sort keys %{$gene_ovlp_q{$gene}})
	{
		if (exists $net_ovlp_t{$_})
		{
			push @lines,$net_ovlp_t{$_};		
		}
	}
	next if (@lines == 0);

	my @tmp = sort values %{$gene_ovlp_q{$gene}};
	my $ovlp_tatio = &overlap_ratio($gene,\%cds_len,\@tmp); # sub 4

	my @gene_ratio = &overlap_ratio_target(\%cds_len,\@lines);  # sub 5

	$out .= "$gene\t$ovlp_tatio\t".(join "\t",@gene_ratio)."\n";
}

print "$out\n";


## sub 1
##
sub read_CDStab
{
	my $file = shift;
	my $hshp = shift;

	open IN, $file or die;
	while (<IN>)
	{
		my @c = split;
		my $id = (split /\./,$c[1])[0];
		$hshp->{$id} += $c[3] - $c[2] + 1;
	}
	close IN;
}


## sub 2
##
sub ID_overlap
{
	my $file = shift;
	my $hshp = shift;

	open IN, $file or die;
	while (<IN>)
	{
		my @c = split;
		next if ($c[3] == 0);
		$c[0] =~ s/^[^\.]+\.//;
		$hshp->{$c[0]} = $_;
	}
	close IN;
}


## sub 3
##
sub gene_vs_overlap
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die;
	while (<IN>)
	{
		my @c = split;
		next if ($c[3] == 0);
		my $numb = @c - 1;
		for (4..$numb)
		{
			my $gene = (split /\./, $c[$_])[0];
			$hshp->{$gene}{$c[0]} = "\t".join " ",@c;
		}
	}
	close IN;
}


## sub 4
##
sub overlap_ratio
{
	my $geneID = shift;
	my $hshp   = shift;
	my $assp   = shift;

	my %cds;
	foreach (@$assp)
	{
		my @tmp = split;
		shift @tmp;
		shift @tmp;
		shift @tmp;
		shift @tmp;
		foreach (@tmp)
		{
			my @comma = split /,/,$_;
			if (/$geneID/){
				$cds{$comma[0]} += $comma[2];
			}
		}
	}

	my $ovlp;
	foreach (sort keys %cds)
	{
		$ovlp += $cds{$_};
	}
	
	my $ratio = $ovlp/$hshp->{$geneID};
	$ratio;
}


## sub 5
##
sub overlap_ratio_target
{
	my $hshp   = shift;
	my $assp   = shift;
	
	my %gene;
	foreach (@$assp)
	{
                my @tmp = split;
                shift @tmp;
                shift @tmp;
                shift @tmp;
                shift @tmp;
                foreach (@tmp)
                {
                        my @comma = split /,/,$_;
			my ($gen,$num) = (split /\./,$comma[0])[0,1];
			if (exists $gene{$gen}{$num}{$comma[3]} and $gene{$gen}{$num}{$comma[3]} < $comma[4])
			{
				$gene{$gen}{$num}{$comma[3]} = $comma[4];
			}
			elsif (!exists $gene{$gen}{$num}{$comma[3]})
			{
				$gene{$gen}{$num}{$comma[3]} = $comma[4];	
			}
                }
        }

	my @aim;
	foreach my $gen(sort keys %gene)
	{
		my $ovlp;
		foreach my $cds(sort keys %{$gene{$gen}})
		{
			my $sz = &caculate_overlap(\%{$gene{$gen}{$cds}}); #sub 6 
			$ovlp += $sz;
		}
		my $ratio = $ovlp/$hshp->{$gen};
		push @aim,"$gen\t$ratio"
	}
	@aim;
}


## sub 6
##
sub caculate_overlap
{
	my $hshp = shift;

	my @starts = sort {$a <=> $b} keys %{$hshp};
	if (@starts == 1)
	{
		my $size = $hshp->{$starts[0]} - $starts[0] + 1;
		return $size;
	}

	my $size;
	my $bg = shift @starts;
	my $end = $hshp->{$bg};
	foreach (@starts)
	{
		if ($_ < $end and $hshp->{$_} <= $end)
		{
			next;
		}
		elsif ($_ < $end and $hshp->{$_} > $end)
		{
			$end = $hshp->{$_};
		} 
		elsif ($_ >= $end)
		{
			$size += $end - $bg + 1;
			$bg = $_;
			$end = $hshp->{$_};
		}
	}

	$size += $end - $bg + 1;
	$size;
}
