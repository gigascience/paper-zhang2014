#!/usr/bin/perl

if (@ARGV != 3)
{
	print "perl $0 <net.ortholog.algn> <align rate: 0.3> <percent in synteny: 0.3>\n";
	exit;
}

use strict;

my $ortholog = shift;
my $alignRate= shift;
my $cutf_syn = shift;

my $out;
open IN, $ortholog or die;
<IN>;
while (<IN>)
{
	my @c = split;
	my $id1 = shift @c;
	my $syn = shift @c;
	my $long= shift @c;

	my @tmp;
	push @tmp,"$id1\t$syn\t$long";
	my $num = @c/4;
	for(1..$num)
	{
		my $id2 = shift @c;
		my $syn2 = shift @c;
		my $long2= shift @c;
		my $ovlp = shift @c;
		
		my $long_f = ($long < $long2) ? $long : $long2;
		my $ratio = $ovlp/$long_f;
		if ($ratio >= $alignRate and $syn2 >= $cutf_syn)
		{
			 push @tmp,"$id2\t$syn2\t$long2\t$ovlp";
		}
	}

	next if (@tmp < 2);
	$out .= join "\t",@tmp;
	$out .= "\n";
}
close IN;


print $out;
