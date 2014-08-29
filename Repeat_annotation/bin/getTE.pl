#!/usr/bin/perl

=head1 Name

getTE.pl  --  get TE elements from sequences according to coordinates

=head1 Description

It should also be used for ncRNA and other block elements.

=head1 Version

  Author: Fan Wei, fanw@genomics.org.cn
  Version: 1.0,  Date: 2009-3-16

=head1 Usage
  % $0  [option] <pos_file> <seq_file>
  --verbose           output verbose information to screen  
  --help              output help information to screen  

=head1 Exmple

 perl ./getTE.pl chr01.gff chr01.fa >  chr01.TE.fa


=cut

use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname); 
use Data::Dumper;

my ($Verbose,$Help);
GetOptions(
	"verbose!"=>\$Verbose,
	"help!"=>\$Help
);
die `pod2text $0` if (@ARGV == 0 || $Help);

my $pos_file = shift;
my $seq_file = shift;

my %Element;

read_gff($pos_file,\%Element);

#print Dumper \%Element;
#exit;

open(IN,$seq_file)||die("failed $seq_file\n");

$/=">"; <IN>; $/="\n";	
while (<IN>) {
	my $chr=$1 if(/^(\S+)/);
	$/=">";
	my $seq=<IN>;
	chomp $seq;
	$seq=~s/\s//g;
	$/="\n";

	my $chr_pp=$Element{$chr};
	my $output;
	foreach  my $TE_id (sort keys %$chr_pp) {
		my $TE_p = $chr_pp->{$TE_id};
		my $TE_seq = substr($seq, $TE_p->[0] - 1, $TE_p->[1] - $TE_p->[0] + 1);
		$TE_seq = Complement_Reverse($TE_seq) if($TE_p->[2] eq '-');
		Display_seq(\$TE_seq);
		$output .= ">$TE_id  seq:$chr:$TE_p->[0]:$TE_p->[1]:$TE_p->[2]\n$TE_seq";
	}
	print $output;
}

close(IN);




####################################################
################### Sub Routines ###################
####################################################

#display a sequence in specified number on each line
#usage: disp_seq(\$string,$num_line);
#		disp_seq(\$string);
#############################################
sub Display_seq{
	my $seq_p=shift;
	my $num_line=(@_) ? shift : 50; ##set the number of charcters in each line
	my $disp;

	$$seq_p =~ s/\s//g;
	for (my $i=0; $i<length($$seq_p); $i+=$num_line) {
		$disp .= substr($$seq_p,$i,$num_line)."\n";
	}
	$$seq_p = ($disp) ?  $disp : "\n";
}
#############################################


#############################################
sub Complement_Reverse{
	my $seq=shift;
	$seq=~tr/AGCTagct/TCGAtcga/;
	$seq=reverse($seq);
	return $seq;

}
#############################################


##scaffold32513270        RepeatMasker    Transposon      1       339     2432    -       .       ID=TE0000001;Target=L1_Canid_ 4799 5
sub read_gff{
	my $file=shift;
	my $ref=shift;
	open (IN,$file) || die ("fail open $file\n");
	while (<IN>) {
		next if(/^\#/);
		s/^\s+//;
		s/\s+$//;
		my @t = split(/\t/);
		my $tname = $t[0];
		my $qname = $1 if($t[8] =~ /^ID=([^;]+);*/);
	
		$ref->{$tname}{$qname} = [$t[3],$t[4],$t[6]];
	}
	close(IN);


}