#!/usr/bin/perl -w
use strict;
die "Usage: perl $0 <*species.ort> <*.ort.stat> <column: e.g. 7> <ratio: 0.8> <stretch>\n" unless @ARGV == 5;
my ($col,$rate,$stretch) = @ARGV[2,3,4];

my $real = (($col-7)/6*2 + 9);

my (%hash,@lines);
my $i = 0;
open (IN,$ARGV[0]) or die $!;
while (<IN>) {
	chomp;
	push @lines,$_;
	my @info = split /\s+/;
	$hash{$info[1]}{$info[2]} = $i;
	$i ++;
}
close IN;

open (IN,$ARGV[1]) or die $!;
while (<IN>) {
	chomp;
	my @info = split /\s+/;
	next unless ($info[$real-1] >= $rate);
	my $index_a = $hash{$info[0]}{$info[4]};
	my $index_b = $hash{$info[0]}{$info[5]};
	my $window = $info[5]-$info[4]+ 1;
	my (%tag,%record);

	foreach my $index ($index_a..$index_b) {
		my $string = $lines[$index];
		my @mes = split /\s+/,$string;

		for (my $k=7;$k<@mes;) {
			if ($mes[$k-1] ne "NA") {
				push @{$tag{$k}},$index;
			}
			$k += 6;
		}
	}
		
	foreach my $lie (sort {$a <=> $b} keys %tag) {
		if ( (1-scalar(@{$tag{$lie}})/$window) <  $rate ) {
			$record{$lie} = 1;
			next;
		} else {
			foreach my $num (@{$tag{$lie}}) {
				my @aaa = split /\s+/,$lines[$num];
				my $ant = ($num-$stretch > 0) ? $num-$stretch : 0;
				my $pos = ($num+$stretch < $#lines) ? $num+$stretch : $#lines;
				$record{$lie}  += &Stretch($aaa[$lie],$aaa[$lie+1],$lie,@lines[$ant..$pos]);
			}
		}
	}
	my @fruit;
	for (my $i=8;$i<@info;$i++) {
		push @fruit,$info[$i-1],$info[$i];
		$i ++;
		my $wo = ($i-9)/2*6+7;
		$record{$wo} = 0 unless (exists $record{$wo});
		push @fruit,$record{$wo};
	}
	my $line = join "\t",@info[0..6],@fruit;
	print "$line\n";
}
close IN;

########################	SUBROUTINE	###############################
sub Stretch {
	my ($chr,$order,$cor,@para) = @_;
	my %temp;
	my $tip = 0;
	foreach my $row (@para) {
		my @info = split /\s+/,$row;
		next if ($info[$cor] eq "NA");
		$temp{$info[$cor]} += 1;
		if ($info[$cor] eq $chr) {
			if( abs($info[$cor+1]-$order) <= 10) {
				$tip = 1;
			}
		}
	}
	my $flag = 0;

	if ($temp{$chr} > 1 && $tip == 1) {
		$flag = 1;
	}
=pod
	foreach my $sca (sort keys %temp ) {
		if ($temp{$sca} > 1) {
			$flag = 1;
			last;
		}
	}
=cut
	return $flag;
}
