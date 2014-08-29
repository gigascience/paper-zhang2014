#!/usr/bin/perl 

=head1 Name

  Ltr2GFF.pl --tran LTR-Finder result from summary format (-w 2) to GFF format

=cut

use strict;
use File::Basename qw(basename);

my $ltr=shift;
my $ltr_name=basename($ltr);
my $gff=$ltr_name."gff";
open IN,$ltr or die "can not open $ltr:$!";
my $chr;
my $i=0;
while(<IN>){
	chomp;
	next if !/^\[/;
	my @c=split(/\t/);
	$c[0]=~/\[\s*(\d+)\]/;
	my $id=$c[1]."_".$1."_ltr";
	my $chr=$c[1];
	$c[2]=~/(\d+)-(\d+)/;
	my ($s,$e)=($1,$2);
	my $strand=$c[-4];
	print "$chr\tLTR_Finder\tLTR\t$s\t$e\t\.\t$strand\t\.\tID=$id;\n";
		
}
close IN;
