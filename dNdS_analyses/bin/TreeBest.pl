#! /usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;
#use FindBin qw($Bin $Script);

if(@ARGV!=3){
	print "perl $0 <tree> <name list> <outfile(treebest)>\n";
	exit();
}

open(IN,"./bin/treebest subtree $ARGV[0] $ARGV[1] |") || die "$!";
open(OUT,">$ARGV[2]") || die "$!";
$/="\;";
my $tree=<IN>;
$tree=~s/\s+//g;
print OUT "$tree";
close IN; close OUT;
