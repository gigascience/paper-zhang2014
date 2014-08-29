#!/usr/bin/perl -w
use strict;

die "Usage: <high_gff_dir> <low_gff_dir> <raw_gff_dir> <gene_list> <pep>!\n" unless @ARGV == 5;
my $high_gff_dir = shift;
my $low_gff_dir = shift;
my $raw_gff_dir = shift;
my $gene_list = shift;
my $pep = shift;

my %high;
opendir HH, $high_gff_dir;
while (my $file = readdir HH) {
	next unless ($file =~ /\.gff$/);
	my $sp = (split /\./, $file)[0];
	next unless ($sp eq "ALLMI" || $sp eq "CROPO" || $sp eq "GAVGA" || $sp eq "PELSI" || $sp eq "CHEMY");
	my %all;
	open HN, "$high_gff_dir/$file";
	while (<HN>) {
		chomp;
		my @info = (split /\s+/);
		next unless ($info[2] eq "mRNA");
		my ($ge, $fs, $pres, $hit);
		if ($info[8] =~ /ID=([^;]+);Shift=(\d+);.*PreStop=(\d+);BestHit=([^;]+);/) {
			($ge, $fs, $pres, $hit) = ($1, $2, $3, $4);
		}
		my $ge0 = $ge;
		$ge0 =~ s/-D\d+$//;
		if ($ge0 eq $hit) {
			push @{$all{$hit}}, [$ge, $info[5], $fs, $pres];
		}
	}
	close HN;
	best_target(\%all, \%high, $sp);
}
closedir HH;

my (%lowp, %lowm);
my @spes;
opendir LH, $low_gff_dir;
while (my $file = readdir LH) {
	next unless ($file =~ /\.gff$/);
	my $sp = (split /\./, $file)[0];
	next if ($sp eq "ALLMI" || $sp eq "CROPO" || $sp eq "GAVGA" || $sp eq "PELSI" || $sp eq "CHEMY" || $sp eq "AllMI" || $sp eq "ANOCA");
	push @spes, $sp;
	my (%plus, %minus);
	open LN, "$low_gff_dir/$file";
	while (<LN>) {
		chomp;
		my @info = (split /\s+/);
		next unless ($info[2] eq "mRNA");
		my ($ge, $fs, $pres, $hit);
		if ($info[8] =~ /ID=([^;]+);Shift=(\d+);.*PreStop=(\d+);BestHit=([^;]+);/) {
			($ge, $fs, $pres, $hit) = ($1, $2, $3, $4);
		}
		my $ge0 = $ge;
		$ge0 =~ s/-D\d+$//;
		push @{$plus{$ge0}}, [$ge, $info[5], $fs, $pres];
		if ($hit ne $ge0) {
			push @{$minus{$hit}}, [$ge, $info[5], $fs, $pres];
		}
	}
	close LN;
	best_target(\%plus, \%lowp, $sp);
	best_target(\%minus, \%lowm, $sp);
}
closedir LH;

my %raw;
read_raw_gff($raw_gff_dir);

my %pge;
$/ = ">";
open PE, $pep;
<PE>;
while (<PE>) {
	chomp;
	my $ge;
	if (/^(\S+)/) {
		$ge = $1;
	}
	$ge = "HOMSA_$ge";
	$pge{$ge} ++;
}
close PE;
$/ = "\n";

@spes = sort @spes;
print "#1.GeneID\t2.ALLMI\t3.CROPO\t4.GAVGA\t5.PELSI\t6.CHEMY\t";
my $n = 6;
foreach my $s (@spes) {
	$n ++;
	print "$n.$s\t";
}
print "55.AssociatedGeneName\t56.Description\t57.Disease\n";
open LI, $gene_list;
<LI>;
while (<LI>) {
	chomp;
	my ($gene, $name, $des, $dis) = (split /\t/)[0,-3,-2,-1];
	next unless $pge{$gene};
	my $num = 0;
	print "$gene\t";
	$gene = (split /_/, $gene)[1];
	foreach my $sp ("ALLMI","CROPO","GAVGA","PELSI","CHEMY")
	{
		if ($high{$gene}{$sp}) {
			print "${sp}_$high{$gene}{$sp}\t";
		} else {
			if ($raw{$gene}{$sp}) {
				@{$raw{$gene}{$sp}} = sort{$b->[0] <=> $a->[0]} @{$raw{$gene}{$sp}};
				my ($rate, $mm) = @{@{$raw{$gene}{$sp}}[0]};
				print "NA,$rate,$mm\t";
			} else {
				print "NA,0,-\t";
			}
		}
	}
	foreach my $sp (@spes) {
		if ($lowp{$gene}{$sp}) {
			print "${sp}_$lowp{$gene}{$sp}\t";
		} else {
			if ($lowm{$gene}{$sp}) {
				print "${sp}_$lowm{$gene}{$sp}\t";
			} else {
				if ($raw{$gene}{$sp}) {
					@{$raw{$gene}{$sp}} = sort{$b->[0] <=> $a->[0]} @{$raw{$gene}{$sp}};
					my ($rate, $mm) = @{@{$raw{$gene}{$sp}}[0]};
					print "NA,$rate,$mm\t";
				} else {
					print "NA,0,-\t";
				}
			}
		}
	}
	print "$name\t$des\t$dis\n";
}
close LI;

sub best_target
{
	my ($tars, $best, $tsp) = @_;
	foreach my $id (keys %$tars) {
		my (@mut, @nomut);
		foreach my $p (@{$$tars{$id}}) {
			if (@$p[2]+@$p[3] == 0) {
				push @nomut, $p;
			} else {
				push @mut, $p;
			}
		}
		my ($gene, $rate, $fn, $pn);
		if (@nomut) {
			@nomut = sort{$b->[1] <=> $a->[1]} @nomut;
			($gene, $rate, $fn, $pn) = @{$nomut[0]};
			$$best{$id}{$tsp} = "$gene,$rate,-";
		} else {
			@mut = sort{$b->[1] <=> $a->[1]} @mut;
			($gene, $rate, $fn, $pn) = @{$mut[0]};
			my $mlog;
			if ($fn) {
				for (my $i = 0; $i < $fn; $i ++) {
					$mlog .= "F";
					$mlog .= "/" if ($i < $fn-1);
				}
			}
			if ($pn) {
				$mlog .= "/" if $mlog;
				for (my $j = 0; $j < $pn; $j ++) {
					$mlog .= "S";
					$mlog .= "/" if ($j < $pn-1);
				}
			}
			$$best{$id}{$tsp} = "$gene,$rate,$mlog";
		}
	}
}

sub read_raw_gff
{
	my $gff_dir = shift @_;
	opendir RH, $gff_dir;
	while (my $file = readdir RH) {
		next unless ($file =~ /\.gff\.gz$/);
		my $sp = (split /\./, $file)[0];
		next if ($sp eq "AllMI" || $sp eq "ANOCA");
		open GF, "gunzip -c $gff_dir/$file |";
		while (<GF>) {
			chomp;
			my @col = (split /\t/);
			next unless ($col[2] eq "mRNA");
			my ($id, $fn);
			if ($col[8] =~ /ID=([^;]+);Shift=(\d+);/) {
				($id, $fn) = ($1, $2);
			}
			my $ge = $id;
			$ge =~ s/-D\d+$//;
			my $fin;
			if ($fn) {
				for (my $i = 0; $i < $fn; $i ++) {
					$fin .= "F";
					$fin .= "/" if ($i < $fn-1);
				}
			} else {
				$fin = "-";
			}
			push @{$raw{$ge}{$sp}}, [$col[5], $fin];
		}
		close GF;
	}
	closedir RH;
}
