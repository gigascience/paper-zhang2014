#!/user/bin/perl

my $gapseq=shift;

open IN,$gapseq;
while(<IN>)
{
	if(/>/)
	{
		my @t=split /\t/;
		
		my $seq=<IN>;
		if($seq =~ /N/)
		{
			#print "$_$seq";
			next;
		}
		print "$_";
	}
}
close IN;
