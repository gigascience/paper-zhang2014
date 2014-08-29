#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*.ort.stat.nr> <*.ort> <Type: e.g. 1:statistics; 2:Blocks>\n" unless @ARGV == 3;
my $type = $ARGV[2];
open (IN1,$ARGV[0]) or die $!;
open (IN2,$ARGV[1]) or die $!;
my ($flag,$mark) = (1,1);
my (%hash,@info,@mes,$file1,$file2);
while (1) {

	my (@register);
	if ($flag == 1) {
		$file1 = <IN1>;
		last unless ($file1);
		chomp $file1;
		@info = split /\s+/,$file1;
	}
	if ($mark == 1) {
		$file2 = <IN2>;
		last unless ($file2);
		chomp $file2;
		@mes = split /\s+/,$file2;
	}
	push @register,$info[0],$mes[1];
	@register = sort {$a cmp $b} @register;
	if ($info[0] eq $mes[1]) {
		if($mes[2] < $info[4]) {
			($flag,$mark) = (0,1);
			next;
		} elsif ($mes[2] >= $info[4] && $mes[2] <= $info[5]) {
			push @{$hash{$info[0]}{$info[4]}},$file2;
			($flag,$mark) = (0,1);
			next;
		} else {
			($flag,$mark) = (1,0);
			next;
		}
	} elsif ($register[0] eq $mes[1]) {
		($flag,$mark) = (0,1);
		next;
	} else {
		($flag,$mark) = (1,0);
		next;
	}
}
if ($type == 2) {
	foreach my $sca (sort keys %hash) {
		foreach my $st (sort {$a <=>$b} keys %{$hash{$sca}}) {
			my @block = @{$hash{$sca}{$st}};
			my $line = join "\n",@block;
			print "####################################################\n";
			print "$line\n";
			print "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n";
		}
	}
} else {
	foreach my $sca (sort keys %hash) {
		foreach my $st (sort {$a <=>$b} keys %{$hash{$sca}}) {
			my @block = @{$hash{$sca}{$st}};
			my %count;
			my (@locus,@temp,@order,$scaf,$col);
			foreach my $string (@block[0..$#block]) {
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
			my $length = $locus[$#locus]-$locus[0]+1;
			my $sum = $order[$#order]-$order[0]+1;
			for (my $coor=7;$coor<$col;) {
				$count{$coor} = 0 unless (exists $count{$coor});
				my $ratio = sprintf "%.2f",$count{$coor}/$sum;
				push @temp,$count{$coor},$ratio;
				$coor += 6;
			}
			my $line = join "\t",$scaf,$locus[0],$locus[$#locus],$length,$order[0],$order[$#order],$sum,@temp;
			print "$line\n";
		}
	}
}
