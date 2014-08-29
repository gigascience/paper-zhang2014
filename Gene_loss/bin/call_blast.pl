#!/usr/bin/perl -w
use strict;
use Cwd 'abs_path';
die "\nUsage: <query_dir> <database_file> <blast type> <out_dir> <suffix of query> <memory for qsub(G)>\n\n" unless @ARGV == 6;
my $query_dir = shift;
my $database_file = shift;
my $blast_type = shift;
my $out_dir = shift;
#my $program = "/share/project002/liqiye/bin/genBlastA/blastall";
my $program = "/opt/blc/genome/biosoft/blast-2.2.23/bin/blastall";
mkdir $out_dir unless -e $out_dir;
my $suffix = shift;
my $mem = shift;

#foreach my $p (\$query_dir, \$database_file, \$out_dir) {
#	$$p = abs_path($$p);
#}

opendir IN, $query_dir;
while (my $file = readdir IN) {
	next unless $file =~ /.+\.$suffix$/;
	my $query_file = "$query_dir/$file";
	my $out_file = "$out_dir/$file.m8";
	my $sh_file = $file =~ /^\d+/ ? "$out_dir/blast_$file.sh" : "$out_dir/$file.sh";
	open SH, ">$sh_file";
	print SH "date\n$program -p $blast_type -i $query_file -d $database_file -o $out_file -F F -a 4 -e 1e-5 -m 8\ndate\n";
	close SH;
	system "qsub -S /bin/sh -cwd -l vf=${mem}G  -q ngb.q -P ngb_un  $sh_file";
}
closedir IN;
