#!/usr/bin/perl

# 2011.09.20

if (@ARGV != 6)
{
	print "perl $0 <.net.axt> <.ortholog> <.target.tab.ovlp> <.query.tab.ovlp> <query.scaf.len> <.cds.len>\n";
	exit;
}

use strict;

my $netAxt = shift;
my $ortho  = shift;
my $ovlp_t = shift;
my $ovlp_q = shift;
my $len    = shift;
my $len_cds= shift;

my %scaf_len;
&read_table_scaffold_len($len,\%scaf_len); #sub 0

my %cds_len;
&read_table_scaffold_len($len_cds,\%cds_len); #sub 0

my %gene_ovlp;
my %id_ovlp1;
&read_overlap_gene_synteny($ovlp_t,\%gene_ovlp,\%id_ovlp1); # sub 1

my %id_ovlp2;
&read_overlap_gene_synteny($ovlp_q,\%gene_ovlp,\%id_ovlp2); # sub 1

my %id_axt;
&read_netAxt($netAxt,\%id_axt);#sub 2

my $out;
open IN,$ortho or die;
while (<IN>)
{
	my @c = split;
	my $n = @c/2;
	my $id1 = $c[0];
	$out .= "$c[0]\t$c[1]\t$cds_len{$id1}";
	for my $i(2..$n)
	{
		my $index = $i * 2 - 2;
		my $id2 = $c[$index];
		my @blocks = &get_orthologous_blocks($id1,$id2,\%gene_ovlp); # sub 3

		my $ovlp = 0;
		foreach my $bl(@blocks) 
		{
			my @coordinate1;
			&netAxt_coordinate_convert($bl,\%id_axt,\%id_ovlp1,\@coordinate1,\%scaf_len,$id1); # sub 4
			my $ovlp1 = &calculate_overlap($bl,\%id_ovlp2,\@coordinate1,$id2); #sub 5
#for(my $i = 0; $i < @coordinate1; $i ++){print "$coordinate1[$i][0] $coordinate1[$i][1] Blocks\n"}
			$ovlp += $ovlp1;
		}

		$index = $i * 2 - 1;
		$out .= "\t$id2\t$c[$index]\t$cds_len{$id2}\t$ovlp"
	}
	$out .= "\n";
}
close IN;

print "#ID1\tPerc_syn1\tCDS_len1\tID2\tPerc_syn2\tCDS_len2\tAlign_len\n";
print $out;


## sub 0
##
sub read_table_scaffold_len
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die;
	while (<IN>)
	{
		my ($id,$len) = (split)[0,1];
		$hshp->{$id} = $len;
	}
	close IN;
}


## sub 1
##
sub read_overlap_gene_synteny
{
	my $file = shift;
	my $hshp = shift;
	my $hsp2 = shift;

	open IN,$file or die "Fail to open $file";
	while (<IN>)
	{
		my @c = split;
		next if ($c[3] == 0);
		my ($id,$chr) = (split /\./,$c[0])[-1,-2];
                my $name = "$chr.$id";
		$hsp2->{$name} = $_;

		my %spe;
		my @genes = /\s+(\S+_[A-Z]{5})/g;
		foreach my $gn(@genes)
		{
			$spe{$gn}++;
		}
		@genes = sort keys %spe;

		foreach my $gn(@genes)
		{
			push @{$hshp->{$gn}},$_;
		}
	}
	close IN;
}


## sub 2
##
sub read_netAxt
{
	my $file = shift;
	my $hshp = shift;

	open IN,$file or die;
	$/ = "\n\n";
	while (<IN>)
	{
		my @lns = split /\n/;
		my ($id,$chr) = split /\s+/,$lns[-3];
		my $name = "$chr.$id";
		$hshp->{$name} = "$lns[-3]\n$lns[-2]\n$lns[-1]\n";
	}
	close IN;
	$/ = "\n";
}


## sub 3
## 
sub get_orthologous_blocks
{
	my $gene1 = shift;
	my $gene2 = shift;
	my $hashp = shift;

	my %num;
	foreach (@{$hashp->{$gene1}})
	{
		my @c = split;
		my ($id,$chr) = (split /\./,$c[0])[-1,-2];
		my $name = "$chr.$id";
		$num{$name}++;
	}
        foreach (@{$hashp->{$gene2}})
        {
                my @c = split;
                my ($id,$chr) = (split /\./,$c[0])[-1,-2];
                my $name = "$chr.$id";
                $num{$name}++;
        }

	foreach (sort keys %num)
	{
		delete $num{$_} if ($num{$_} == 1);
	}

	my @aim = sort keys %num; 	
	@aim;
}


## sub 4   
## $bl,\%id_axt,\%id_ovlp1,\@coordinate1,\%scaf_len
sub netAxt_coordinate_convert
{
	my $blockID = shift;
	my $axt_hsp = shift;
	my $bl_hsp  = shift;
	my $assp    = shift;
	my $len_hsp = shift;
	my $ID      = shift;

	my @tmp_;
	my %num_conver;
	my @tmp = split /\s+/,$bl_hsp->{$blockID};
	for(1..$tmp[3])
	{
		my ($nd,$bg,$id) = (split /,/, (pop @tmp))[-1,-2,0];
		$id = (split /\./,$id)[0];
		next if ($id ne $ID);
		$num_conver{$bg} = 0;
		$num_conver{$nd} = 0;
		push @tmp_,[$bg,$nd];
	}

	my ($ln1,$ln2,$ln3) = (split /\n/,$axt_hsp->{$blockID})[0,1,2];
	my ($chr1,$bg1,$nd1,$chr2,$bg2,$nd2,$strand) = (split /\s+/,$ln1)[1,2,3,4,5,6,7];
	chomp $ln2;
	my $long = length($ln2) - 1;	
	my ($pos1,$pos2) = ($bg1,$bg2);
	$pos1--;
	$pos2--;
	for(0..$long)
	{
		my $str1 = substr($ln2,$_,1);
		$pos1++ if ($str1 ne "-");
		my $str2 = substr($ln3,$_,1);
		$pos2++ if ($str2 ne "-");
		if (exists $num_conver{$pos1})
		{
			if ($strand eq "+")
			{
				$num_conver{$pos1} = $pos2;
			}elsif ($strand eq "-")
			{
				$num_conver{$pos1} = $len_hsp->{$chr2} - $pos2 + 1;
			}else
			{
				print STANDERR "Error strand\n$blockID\n";
			}
		}
	}

	for(my $i=0;$i<@tmp_;$i++)
	{
		my $b = $num_conver{$tmp_[$i][0]};
		my $d = $num_conver{$tmp_[$i][1]};
		if ($b < $d)
		{
			push @{$assp},[$b,$d];
		}else
		{
			push @{$assp},[$d,$b];
		}
	}
}


## sub 5
## calculate_overlap($bl,\%id_ovlp2,\@coordinate1
sub calculate_overlap
{
        my $blockID = shift;
        my $bl_hsp  = shift;
        my $assp    = shift;
	my $ID 	    = shift;

	my @postions2;
        my @tmp = split /\s+/,$bl_hsp->{$blockID};
        for(1..$tmp[3])
        {
                my ($nd,$bg,$id) = (split /,/, (pop @tmp))[-1,-2,0];
                $id = (split /\./,$id)[0];
                next if ($id ne $ID);
                push @postions2,[$bg,$nd];
        }

	my @ref = sort {$a->[0] <=> $b->[0]} @$assp;
	my @pre = sort {$a->[0] <=> $b->[0]} @postions2;

	my $long = 0;
	my $pre_pos = 0;
	for (my $i=0; $i<@ref; $i++) 
	{
		for(my $j=$pre_pos; $j<@pre; $j++)
		{
			if ($pre[$j][1] < $ref[$i][0])
			{
				$pre_pos++;
				next;
			}
			if ($pre[$j][0] > $ref[$i][1])
			{
				last;
			}
			my $overlap_size = &overlap_size($pre[$j],$ref[$i]); # sub 6
			$long += $overlap_size;	
		}
	}
	return $long;
}


## sub 6
##
sub overlap_size {
        my $block1_p = shift;
        my $block2_p = shift;

        my $combine_start = ($block1_p->[0] < $block2_p->[0]) ?  $block1_p->[0] : $block2_p->[0];
        my $combine_end   = ($block1_p->[1] > $block2_p->[1]) ?  $block1_p->[1] : $block2_p->[1];

        my $overlap_size = ($block1_p->[1]-$block1_p->[0]+1) + ($block2_p->[1]-$block2_p->[0]+1) - ($combine_end-$combine_start+1);

        return $overlap_size;
}


