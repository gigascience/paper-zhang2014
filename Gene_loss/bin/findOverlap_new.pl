#!/usr/bin/perl -w
use strict;

if (@ARGV != 2) {
	print <<"Usage End.";

Description:

	The two input files can be in pos format or first five Columns corresponding to pos format.

	The format of output file: [example]
	ame.Group1.64	scaffold107	+	1149772 1150322 551	2	ame.Group4.17,+,326,209	ame.Group16.8,-,72,72
	Column 1: the query ID;
	Column 2: chromosome ID;
	Column 3: the query strand;
	Column 4: the query start;
	Column 5: the query end;
	Column 6: the query size;
	Column 7: number of blocks overlapped with ame.Group1.64;
	Column 8: the first subject block ame.Group4.17 overlapped with ame.Group1.64, + is the strand of ame.Group4.17, 326 is its own size, 209 is the overlapped size;
	Column 9: the second subject block ame.Group16.8 overlapped with ame.Group1.64, - is the strand of ame.Group16.8, numbers has the same meaning as last column;

Version:
	
	Author: jinlijun, jinlijun\@genomics.org.cn
	Version: 1.0,  Date: 2011-05-18

Usage
	
	perl findOverlap.pl <ref> [pre]

Example:
	
	perl findOverlap.pl a.pos b.pos >a.pos.overlap

Usage End.

	exit;
}

my $ref_file = shift;
my $pre_file = shift;

my (@ref, @pre);
read_pos_file($ref_file, \@ref);
read_pos_file($pre_file, \@pre);

my ($pb, $pe) = (0, 0);
my $next_scaf;
for (my $i = 0; $i < @ref; $i ++) {
	my ($id, $scaf, $strand, $beg, $end) = @{$ref[$i]};
	my $leng = $end - $beg + 1;
	print "$id\t$scaf\t$strand\t$beg\t$end\t$leng\t";
	my @over;
	my $log = 0;
	my $max_end = -1;
	for (my $j = $pb; $j < @pre; $j ++) {
		$pe = $j;
		my ($id0, $scaf0, $strand0, $beg0, $end0) = @{$pre[$j]};
		if ($scaf0 eq $scaf) {
			if ($beg0 <= $end && $end0 >= $beg) {
				my $len = $end0 - $beg0 + 1;
				my $mbeg = ($beg < $beg0) ? $beg : $beg0;
				my $mend = ($end > $end0) ? $end : $end0;
				my $overlen = ($end-$beg+1)+($end0-$beg0+1)-($mend-$mbeg+1);
				push @over, [$id0, $strand0, $len, $overlen];
				$max_end = $end0 if ($end0 > $max_end);
			} elsif ($end0 < $beg) {
				my $next_beg = $beg;
				$next_beg = @{$ref[$i+1]}[3] if ($i < @ref-1);
				$pb ++ if ($max_end < $next_beg);
				next;
			} else {
				print_over(\@over);
				$log = 1;
				last;
			}				
		} else {
			if ($scaf0 gt $scaf) {
				print_over(\@over);
				$log = 1;
				last;
			} else {
				$pb ++;
				next;
			}
		}
	}
	if ($pe == @pre-1 && !$log) {
		print_over(\@over);
	}
}

sub read_pos_file
{
	my ($in_file, $pos) = @_;
	open IN, $in_file;
	while (<IN>) {
		chomp;
		next if /^#/;
		my @info = (split /\s+/)[0,1,2,3,4];
		push @$pos, [@info];
	}
	close IN;
	@$pos = sort{$a->[1] cmp $b->[1] or $a->[3] <=> $b->[3] or $a->[4] <=> $b->[4]} @$pos;
}

sub print_over
{
	my $arr = shift;
	my $overnum = @$arr;
	print "$overnum\t";
	foreach my $k (@$arr) {
		my $out = join(",", @$k);
		print "$out\t";
	}
	print "\n";
}
