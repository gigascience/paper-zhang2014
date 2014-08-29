#! /usr/bin/perl -w
use strict;
#use File::Basename;
use Getopt::Long;
#use FindBin qw($Bin $Script);

if (@ARGV!=3){
        print "perl phylip.pl <fa(SATe)> <outfile1(phylip)> <outfile2(seqname list)>\n";
		exit();
}

my %Code=("TTT"=>1, "TTC"=>1, "TTA"=>1, "TTG"=>1, "CTT"=>1, "CTC"=>1, "CTA"=>1, "CTG"=>1,
		  "ATT"=>1, "ATC"=>1, "ATA"=>1, "ATG"=>1, "GTT"=>1, "GTC"=>1, "GTA"=>1, "GTG"=>1,
		  "TCT"=>1, "TCC"=>1, "TCA"=>1, "TCG"=>1, "CCT"=>1, "CCC"=>1, "CCA"=>1, "CCG"=>1,
		  "ACT"=>1, "ACC"=>1, "ACA"=>1, "ACG"=>1, "GCT"=>1, "GCC"=>1, "GCA"=>1, "GCG"=>1,
		  "TAT"=>1, "TAC"=>1, "CAT"=>1, "CAC"=>1, "CAA"=>1, "CAG"=>1, "AAT"=>1, "AAC"=>1,
		  "AAA"=>1, "AAG"=>1, "GAT"=>1, "GAC"=>1, "GAA"=>1, "GAG"=>1, "TGT"=>1, "TGC"=>1,
		  "TGG"=>1, "CGT"=>1, "CGC"=>1, "CGA"=>1, "CGG"=>1, "AGT"=>1, "AGC"=>1, "AGA"=>1,
          "AGG"=>1, "GGT"=>1, "GGC"=>1, "GGA"=>1, "GGG"=>1); 

open (IN,"$ARGV[0]")||die"can't open $ARGV[0]";
my%Seq;
my@aim;
my$name;
while(<IN>){
	chomp;
	if(/^>/){
		$name=$_;
		$name=~s/^>//g;
		$name=~s/\s+//g;
		push(@aim,$name);
		
	}
	else{
		$Seq{$name}.=$_;
	}
	
}
close IN;
my $num =@aim;
my $len =length($Seq{$aim[0]});

open(OUT1,">$ARGV[1]") || die "$!";
open(OUT2,">$ARGV[2]") || die "$!";
print OUT1 "$num  $len\n";
foreach my$k(@aim){
	print OUT2 "$k\n";
	my$seq;
	for(my$i=0;$i<$len;$i+=3){
		my$code=substr($Seq{$k},$i,3);
		if(exists $Code{$code}){
			$seq.=$code;
		}
		else{
			$seq.="---";
		}
	}
	print OUT1 "$k   $seq\n";
	#print length($Seq{$k})." $k $Seq{$k}\n"; 
}
close OUT1; close OUT2;
