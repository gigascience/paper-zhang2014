#!/usr/bin/perl

#2011.10.03

if (@ARGV != 1)
{
	print "perl $0 <dir>\n";
	exit;
}

use strict;

my $dir = shift;

`perl /panfs/ANIMAL/GROUP/group003/libo/GAP/02.annotation/gene/combine/gff_CDSLength_ident_filter.pl tae_gal_hg.gff.nr.gff 40 > tae_gal_hg.gff.nr.gff40 2> tae_gal_hg.gff.nr.gff40.unQ`;
`perl /panfs/ANIMAL/GROUP/group003/libo/GAP/02.annotation/gene/check/FindOverlapAtCDSlevel.pl tae_gal_hg.gff.nr.gff40 tae_gal_hg.gff.nr.gff40 | awk '\$1 != \$2 && (\$11 >=0.5 || \$12 >= 0.5 )' > ovlp.tab`;
`perl  /panfs/ANIMAL/GROUP/group003/libo/GAP/02.annotation/gene/check/overlap_filter.pl tae_gal_hg.gff.nr.gff40 ovlp.tab > tae_gal_hg.gff.nr.gff40.rmOv.gff 2> ovlp.tab.rm`;
