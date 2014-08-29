#!/usr/bin/perl -w
=head1 Description and Usage
	out_format.pl --> to filter the .out file  
	
  Eg. perl out_format.pl <.out> 

=head1 About 
	Created at 02/18/2013 11:16:34 AM, by LiHui
=cut
use strict;
use Getopt::Long;
use File::Basename qw(basename dirname) ;
use FindBin '$Bin';
use Cwd 'abs_path';
use List::Util qw(min max);

my ($Help, $Step);
GetOptions(
		"help"  => \$Help,
		"step:s" => \$Step 
	);
die `pod2text $0` if ($Help || @ARGV == 0);

#===================== Global Variable =====================#
my $fout = shift; 

#===================== Main process =====================#
open IN,$fout || die $! ;
$_ = <IN> ;
print $_ ;
$_ = <IN> ;
print $_ ;
$_ = <IN> ;
print $_ ;
while (<IN>){
	next if ($_ =~ /SW/);
	next if ($_ =~ /score/);
	next if ($_ =~ /^\s+$/) ;
	print $_; 
}
close IN ; 


#=====================  Subroutines =====================#






