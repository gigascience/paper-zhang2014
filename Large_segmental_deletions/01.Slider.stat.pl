#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*species.ort> <cutoff: e.g. 10> <step size>\n"  unless @ARGV == 3;
my ($cutoff,$step,$outdir) = @ARGV[1,2,3];

open (IN,$ARGV[0]) or die $!;
#open (OT,">$outdir/stat.result.$cutoff") or die $!;

my (@lines);

my $first = <IN>;	chomp $first;

push @lines,$first;

while (1) {
	
	my @info = split /\s+/,$first;

	my $line1 = <IN>;
	last unless $line1;
	chomp $line1;
	my @info1 = split /\s+/,$line1;

	if ($info1[1] eq $info[1]) {

	} else {
		&dealBlock(\@lines) if (@lines >=$cutoff);
		@lines = ();
	}
	$first = $line1;
	push @lines,$first;
}
&dealBlock(\@lines) if (@lines >=$cutoff);
close IN;
#close OT;

################	SUBROUTINE	####################
sub dealBlock {
	my @block = @{$_[0]};
	my $st = 1;
	for (my $i=$cutoff;$i<=@block;) {
		my $index_a = $st-1;
		my $index_b = $i-1;
		my %count;
		my (@locus,@temp,@order,$scaf,$col);
		foreach my $string (@block[$index_a..$index_b]) {
			my @mes = split /\s+/,$string;
			($scaf,$col) = ($mes[1],scalar(@mes));
			push @locus,@mes[4,5];
			push @order,$mes[2];
			for (my $k=7;$k<@mes;) {
				if ($mes[$k-1] eq "NA") {
					$count{$k} ++;
				}
				$k += 6;
			}
		}
		for (my $coor=7;$coor<$col;) {
			$count{$coor} = 0 unless (exists $count{$coor});
			my $ratio = sprintf "%.2f",$count{$coor}/$cutoff;
			push @temp,$count{$coor},$ratio;
			$coor += 6;
		}
		my $length = $locus[$#locus]-$locus[0]+1;
		my $sum = $order[$#order]-$order[0]+1;
		my $line = join "\t",$scaf,$locus[0],$locus[$#locus],$length,$order[0],$order[$#order],$sum,@temp;
		print "$line\n";
		$st += $step;
		$i += $step;
	}
}
