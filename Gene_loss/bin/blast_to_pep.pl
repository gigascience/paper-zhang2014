#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin $Script);

die "Usage: <in_dir> <pep> <split_N> <out_dir> <step(1|2)>!\n" unless @ARGV == 5;
my $in_dir = shift;
my $pep = shift;
my $split_N = shift;
my $out_dir = shift;
my $step = shift;

mkdir $out_dir unless -e $out_dir;

my $log = 0;
my @sh_files;
opendir DH, $in_dir;
while (my $file = readdir DH) {
	next unless ($file =~ /\.pep$/);
	my $sp = (split /\./, $file)[0];
    if ($step == 1) {
		mkdir "$out_dir/$sp" unless -e "$out_dir/$sp";
		mkdir "$out_dir/$sp/split" unless -e "$out_dir/$sp/split";
		open SH, " >$out_dir/$sp/split/work.sh";
		print SH "perl $Bin/Split_fasta.pl -seq $in_dir/$file -nf $split_N -od $out_dir/$sp/split\n";
		print SH "perl $Bin/call_blast.pl $out_dir/$sp/split $pep blastp $out_dir/$sp/split pep 0.1\n";
		close SH;
		chdir "$out_dir/$sp/split";
		`sh $out_dir/$sp/split/work.sh`;
	} else {
		die unless ($step == 2);
		`perl $Bin/blast_sh_e_o.pl $out_dir/$sp/split >$out_dir/$sp/error.log`;
		my ($line_num, $n) = (0,0);
		open ER, "$out_dir/$sp/error.log";
		while (<ER>) {
			chomp;
			$line_num ++;
			$n = (split /\s+/)[0];
		}
		close ER;
		unless ($line_num == 1 && $n == $split_N) {
			$log = 1;
			print "$out_dir/$sp\n";	
		}

		open CH, " >$out_dir/$sp/work.sh";
		print CH "date\n";
		print CH "cat split/*.m8 >$sp.m8\n";
		print CH "perl $Bin/blast_filter.pl -i $sp.m8 -f $in_dir/$file -f $pep -best >$sp.m8.best\n";
		print CH "date\n";
		close CH;
		
		push @sh_files, "$out_dir/$sp/work.sh";
		#chdir "$out_dir/$sp";
		#sh $out_dir/$sp/work.sh`;
		#`qsub -S /bin/sh -cwd -l vf=6G -q ngb.q -P ngb_un $out_dir/$sp/work.sh`;
	}
}
closedir DH;

if ($step == 2 && !$log) {
	foreach my $file (@sh_files) {
		my $dir = $file;
		$dir =~ s/\/work\.sh$//;
		`rm $dir/split/*.sh.*`;
		chdir $dir;
		`qsub -S /bin/sh -cwd -l vf=2G -q ngb.q -P ngb_un $file`;
	}
}

