#!/usr/bin/perl
=head1 Description

 split fasta file and convert to 2bit format for lastz pipeline;

=head1 Version

 Yongli Zeng, zengyongli@genomics.cn
 Version 0.9, 2011-07-25

=head1 Usage

 perl split_fasta.pl in.fa outdir splitn mode(nor/avg) conv(yes/no)

=cut
use strict;
use FindBin qw($Bin);

# in.fasta outdir splitn type
die `pod2text $0` if (@ARGV != 5);
my $in = shift;
my $dir = shift;
my $splitn = shift;
my $mode = shift;
my $conv = shift;
chomp($conv);
my $str;

if (-e "$dir"){
	print "$dir exists!\n";
}
`mkdir -p $dir`;
avglensplit() if ($mode eq "avg");
normalsplit() if ($mode eq "nor");

####### old split
sub normalsplit(){
	my $total = `grep -c ">" $in`;	#total line
	my $seg = int($total / $splitn + 0.5);	# line number of each segment
	my $linecount = 0;	# line counter for split
	my $i = 1;	# split file number
	open IN, "<$in" or die "can't open!\n";
	$/ = ">";
	my $name = "split_".$i.".fasta";
	open OUT, ">$dir/$name" or die "can't open $dir/$name\n";
	<IN>;
	while (1){
		$str = <IN>;
		$str =~ s/>$//;
		$linecount++;
		print OUT ">$str";
		last if (eof);
		if ($linecount == $seg){
			close OUT;
			my $new = $name;
			$new =~ s/fasta$/2bit/g;
			`$Bin/faToTwoBit $dir/$name $dir/$new` if ($conv eq "yes");
			$i++ if ($i < $splitn);
			$name = "split_".$i.".fasta";
			open OUT, ">$dir/$name" or die "can't open $dir/$name\n";
			$linecount = 0;
		}
	}
	close OUT;
	my $new = $name;
	$new =~ s/fasta$/2bit/g;
	`$Bin/faToTwoBit $dir/$name $dir/$new` if ($conv eq "yes");
}

########### average length
sub avglensplit(){
	my %seq;
	my $total = 0;
	open IN, "<$in" or die "read fasta failure!\n";
	while ($str = <IN>){
		chomp($str);
		$total += length($str) unless ($str =~ /^>/);
	}
	close;
	my $seg = int ($total / $splitn);
	#warn "$total\t$seg\n";

	my $lencount = 0;
	my $i = 1;
	my $flag = 1;
	$i = sprintf "%05d", $i;
	my $name = "split_".$i.".fasta";
	open OUT, ">$dir/$name" or die "can't open!\n";
	open IN, "<$in" or die "$in failure!\n";
	$/ = ">";
	<IN>;
	$/ = "\n";
	while (1){
		my $head = <IN>;
		$head =~ s/\s+$//g;
		my $input = ">$head";
		$/ = ">";
		$str = <IN>;
		$str =~ s/>$//;
		my $rawstr = $str;
		$str =~ s/\s//g;
		$/ = "\n";
		$input .= "\n$rawstr";
		if ($lencount + length($str) >= $seg){
			if ($lencount + length($str) < $seg * 1.3){
				print OUT "$input";
				close OUT;
				my $new = $name;
				$new =~ s/fasta$/2bit/g;
				if ($conv eq "yes"){
					`$Bin/faToTwoBit $dir/$name $dir/$new`;
				}
				last if (eof);
				$i++;
				$i = sprintf "%05d", $i;
				$name = "split_".$i.".fasta";
				open OUT, ">>$dir/$name" or die "can't open $dir/$name\n";
				$lencount = 0;
				$flag = 1;
			}else{		# exceed
				if ($flag){		# new file without any input
					print OUT "$input";
					close OUT;
					my $new = $name;
					$new =~ s/fasta$/2bit/g;
					if ($conv eq "yes"){
						`$Bin/faToTwoBit $dir/$name $dir/$new`;
					}
					last if (eof);
					$i++;
					$i = sprintf "%05d", $i;
					$name = "split_".$i.".fasta";
					open OUT, ">>$dir/$name" or die "can't open $dir/$name\n";
					$lencount = 0;
					$flag = 1;
				}else{		# present file has some input
					close OUT;
					my $new = $name;
					$new =~ s/fasta$/2bit/g;
					if ($conv eq "yes"){
						`$Bin/faToTwoBit $dir/$name $dir/$new`;
					}
					$i++;
					$i = sprintf "%05d", $i;
					$name = "split_".$i.".fasta";
					open OUT, ">>$dir/$name" or die "can't open $dir/$name\n";
					print OUT "$input";
					$lencount = length($str);
					$flag = 0;
				}
			}
		}else{
			print OUT "$input";
			$lencount += length($str);
			$flag = 0;
		}
		if (eof){
			#warn "$lencount\n";
			close OUT;
			my $new = $name;
			$new =~ s/fasta$/2bit/g;
			if ($conv eq "yes"){
				`$Bin/faToTwoBit $dir/$name $dir/$new`;
			}
			last;
		}
	}
}

