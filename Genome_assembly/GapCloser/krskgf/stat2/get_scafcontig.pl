#! /usr/bin/perl -w
use strict ;

my $scaf = shift ;

open IN , $scaf ;

$/=">";<IN>;$/="\n";
while(<IN>){
        my $gapsize = 0 ;
        my $scaftigid = 0 ;
        my $scaffid = (split /\s+/ )[0] ;
        $/=">";
        chomp(my $seq = <IN>) ;
        $seq =~ s/\s+//g ;
        my @contig = split /N+/ , $seq ;
        my @Nseq = split /[ACGTacgt]+/ , $seq ;
        for(my $i = 0 ; $i < @contig ; $i++)
        {
			my $ctg_len = length $contig[$i] ;
	    	if( $ctg_len < 70 && $i != 0 && $i != @contig-1 )
			{
				$gapsize += $ctg_len + length($Nseq[$i]);
				#my $Ntmp = shift @Nseq ;
				#$gapsize += length $Nseq[$i] ;
			}
			else{
		    	if($i == 0 )
				{
					print ">$scaffid"."_$scaftigid\t$gapsize\n$contig[$i]\n";
					$scaftigid++ ;
					$gapsize = 0;
				}else{
					my $Ntmp2 = length $Nseq[$i] ;
					$gapsize += $Ntmp2 ;
					print ">$scaffid"."_$scaftigid\t$gapsize\n$contig[$i]\n";
					$scaftigid++;
					$gapsize = 0 ;
				}
		}

		#if($i ==0 ) {$gapsize = 0 ;}
		#else {
		#        my $Ntmp = pop @Nseq ;
		#        $gapsize = length $Ntmp ;
		#}
		#print ">$scaffid"."_$scaftigid\t$gapsize\n$contig[$i]\n";
		#$scaftigid++;
        }
        $/="\n";
}
close IN ;

