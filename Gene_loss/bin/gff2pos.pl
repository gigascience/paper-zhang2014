#!/usr/bin/perl -w
use strict;
die "Usage: <gff> <type[1|2|3](1:gene.pos; 2:cds.pos; 3:intron.pos)>\n" unless @ARGV == 2;
my $type = $ARGV[1];

if ($type == 1) {
	my %genePos;
	&getGenePos($ARGV[0], \%genePos);
	foreach my $id (sort keys %genePos) {
		my ($chr, $strand, $bg, $ed) = @{$genePos{$id}};
		print "$id\t$chr\t$strand\t$bg\t$ed\n";
	}
} elsif ($type == 2) {
	my %cdsPos;
	&getcdsPos($ARGV[0], \%cdsPos);
	&output(\%cdsPos);
} elsif ($type == 3) {
	my %intronPos;
	&getIntronPos($ARGV[0], \%intronPos);
	&output(\%intronPos);
}

##########################################################################################
##################################### subroutine #########################################
##########################################################################################
sub output {
	my ($ref) = @_;
	foreach my $id (sort keys %$ref) {
		foreach my $p (@{$ref->{$id}}) {
			my ($id, $chr, $strand, $bg, $ed) = @$p;
			print "$id\t$chr\t$strand\t$bg\t$ed\n";
		}
	}
}

## get the location of each gene
sub getGenePos {
	my ($in_file, $ref) = @_;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}
	while (<IN>) {
		my @info = split /\s+/;
		next unless $info[2] eq "mRNA";
		die unless $info[8] =~ /^ID=(\S+?);/;
		my $id = $1;
		$ref->{$id} = [$info[0], $info[6], $info[3], $info[4]]; ## id chr strand bg ed
	}
	close IN;
}

## get cds pos of each gene
sub getcdsPos {
	my ($in_file, $ref) = @_;
	my %tmp;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}

	while (<IN>) {
		my @info = split /\s+/;
		next unless $info[2] eq "CDS";
		die unless $info[8] =~ /^Parent=(\S+?);/;
		my $id = $1;
		push @{$tmp{$id}}, [$info[0], $info[3], $info[4], $info[6]]; ## chr bg ed strand
	}
	close IN;

	foreach my $id (keys %tmp) {
		my $strand = $tmp{$id}->[0]->[3];
		if ($strand eq "+") {
			@{$tmp{$id}} = sort {$a->[1] <=> $b->[1]} @{$tmp{$id}};
		} elsif ($strand eq "-") {
			@{$tmp{$id}} = sort {$b->[1] <=> $a->[1]} @{$tmp{$id}};
		} else {
			die;
		}
		my $num;
		foreach my $p (@{$tmp{$id}}) {
			$num ++;
			my $cds_id = "${id}_CDS$num";
			my ($chr, $bg, $ed, $strand) = @$p;
			push @{$ref->{$id}}, [$cds_id, $chr, $strand, $bg, $ed];
		}
	}
}

# get intron pos of each gene
sub getIntronPos {
	my ($in_file, $ref) = @_;
	my %tmp;
	if ($in_file =~ /\.gz$/) {
		open IN, "gunzip -c $in_file | ";
	} else {
		open IN, $in_file;
	}

	while (<IN>) {
		my @info = split /\s+/;
		next unless $info[2] eq "CDS";
		die unless $info[8] =~ /^Parent=(\S+?);/;
		my $id = $1;
		push @{$tmp{$id}}, [$info[0], $info[3], $info[4], $info[6]]; ## chr bg ed strand
	}
	close IN;

	foreach my $id (keys %tmp) {
		my $strand = $tmp{$id}->[0]->[3];
		@{$tmp{$id}} = sort {$a->[1] <=> $b->[1]} @{$tmp{$id}};
		my @intron;
		for (my $i = 0; $i < @{$tmp{$id}}-1; $i ++) {
			my ($chr1, $bg1, $ed1, $strand1) = @{$tmp{$id}->[$i]};
			my ($chr2, $bg2, $ed2, $strand2) = @{$tmp{$id}->[$i+1]};
			my ($intron_bg, $intron_ed) = (sort {$a <=> $b}($bg1, $ed1, $bg2, $ed2))[1,2];
			$intron_bg ++;
			$intron_ed --;
			push @intron, [$chr1, $intron_bg, $intron_ed, $strand1];
		}
		if ($strand eq "+") {
			@intron = sort {$a->[1] <=> $b->[1]} @intron;
		} elsif ($strand eq "-") {
			@intron = sort {$b->[1] <=> $a->[1]} @intron;
		} else {
			die;
		}

		my $num;
		foreach my $p (@intron) {
			$num ++;
			my $intron_id = "${id}_intron$num";
			my ($chr, $bg, $ed, $strand) = @$p;
			push @{$ref->{$id}}, [$intron_id, $chr, $strand, $bg, $ed];
		}
	}
}
