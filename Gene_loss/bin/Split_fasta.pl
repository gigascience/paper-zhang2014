#!/usr/bin/perl

my $Version =  "V.1.3";
my $Author  =  "HongkunZheng";
my $Date    =  "2003-12-22";
my $Update  =  "2003-12-22 14:35";
my $Contact =  "zhenghk\@genomics.org.cn";
my $Function=  "Split fasta sequence into files or sequences!";

#-------------------------------------------------------------------
#-------------------------------------------------------------------


use strict;

my $version = "V.1.3"; #create version

=head1 NAME:

Split_fasta.pl

=head1 SYNOPSIS:

Split_fasta.pl [-options]

Options

		-seq           Path/input_file , must be given (string)

		[split sequence into sequences]
		-overlap       [Number of overlap] (number)
		-max           [Maximum length of each sequence] (number)
		-nl            Number of sequences what you want to split one sequence into
		-out           Path/output_file (string)

		[split fasta file into files]
		-nf            used in split fasta into files, Number of files to be split.
		-ns            used in split fasta into files, Number of sequences into one file
		-od            used in split fasta into files, output directory
		
		-h or -help    show help , have a choice
		-i or -info    show document info with perldoc , have a choice
		
=head1 DESCRIPTION:

Split FASTA file into files or sequences.

=head2 INPUT:

Seq file in FASTA format.

=head2 OUTPUT:

Seq file in FASTA format.

=head1 CONTACT:

Hongkun Zheng: zhenghk@genomics.org.cn

=cut # doc end

use Getopt::Long;

my %opts;

GetOptions(\%opts,"seq:s","out:s","od:s","max=i","ns:i","nl:i","nf:i","overlap=i","help","info");

if(defined($opts{info}))
{
	exec("perldoc $0");
	exit(0);
}

if(defined($opts{help}) || !defined($opts{seq}))
{
	Usage();
}

if(!defined($opts{nf}) && !defined ($opts{ns}) && !defined($opts{overlap}))
{
	Usage();
}




if (defined $opts{nf} || defined $opts{ns}){
	
	my $group_num = defined $opts{nf} ? $opts{nf} : "10000000";
	my $fasta_file = defined $opts{seq} ? $opts{seq} : "";
	my $output_dir = defined $opts{od} ? $opts{od} : "./";
	
	$output_dir =~s/\/$//;
	
	if(!-d $output_dir){
		system("mkdir $output_dir");
	}
	

	#my ($fasta_file,$group_num,$normal) = @ARGV;
	
	my $seq_sum = `cat $fasta_file | grep ">" | wc -l`;
	$seq_sum =~ /(\d+)/;
	$seq_sum = $1;
	
	my $dir='';
	my $pre='';
	my $post='';
	
	if ($fasta_file =~ /^(.*\/)([^\/^\.]+)\.([^\/]+)$/) 
	{
		$dir = $1;
		$pre = $2; 
		$post = $3;
	}
	elsif($fasta_file =~ /^([^\/^\.]+)\.([^\/]+)$/)
	{
		$dir = "./";
		$pre = $1; 
		$post = $2;
	}
	else { 
		die"the infile should is *.*\n"; 
	}
	
	
	print "$pre.$post	$seq_sum\n";
	
	my $each = 0;
	
	if (defined $opts{ns}){
		$each = $opts{ns};
	}
	else {
		$each = int($seq_sum/$group_num);
	}
	
	#print $each,"\n";
	
	open(IN,$fasta_file);
	my $seq_num = 0;
	my $out_num = 0;
	while(<IN>)
	{
		if(/^\>/) 
		{ 
			if ($seq_num % $each == 0 && $out_num < $group_num) 
			{ 
				if($seq_num == $each) { print "$output_dir\/$pre\_$out_num\.$post	$seq_num\n"; }
				close(OUT);
				$out_num++;
				$seq_num = 0;
				open(OUT,">$output_dir\/$pre\_$out_num\.$post")||die"outout error [$output_dir\/$pre\_$out_num\.$post]";
			}
			$seq_num++;
		}
		print OUT $_;
	}
	
	print "$output_dir\/$pre\_$out_num\.$post	$seq_num\n";
	close(IN);
}



#####################################

if (defined $opts{overlap}){
	

	if(!defined($opts{out}))
	{
		Usage();
	}
	
	
	print("\n============================================================\n");
	my $Time_Start = sub_format_datetime(localtime(time())); #start time
	print "Now = $Time_Start\n\n";
	
	PrintParam();
	
	if(defined $opts{max} && $opts{overlap} >= $opts{max})
	{
		print "Error: The length of overlap is greater than or equal the maximum length of each sequence!\n";
		exit(0);
	}
	
	my($name_temp , $flag , $length , $j , $start , $seq_temp);
	
	my($index , $i , $print , $original , $name , $seq , $len);
	
	open(Handle , "<$opts{seq}") || die("ERROR! Can't read <$opts{seq}>:$!\n");
	open(Handle_out , ">$opts{out}") || die("ERROR! Can't create <$opts{out}>:$!\n");
	while(<Handle>)
	{
		chomp;
	
		if($_ =~ m/^>(\S+)/)
		{
			$name_temp = $1;
	
			if($flag)
			{
				$length = length($seq);
				
				if (!defined $opts{max} && defined $opts{nl}){
					$opts{max}= int($length/$opts{nl}) + $opts{overlap};
				}
				
					
				
				if($length > $opts{max})
				{
					for($j = 0 ; $j * ($opts{max} - $opts{overlap}) < $length ; $j ++)
					{
						$start = $j * ($opts{max} -  $opts{overlap});
	
						$seq_temp = substr($seq , $start , $opts{max});
	
						$len = length($seq_temp);
	
						$index = $original;
	
						$index =~ s/$name/$name\_$length\_$start/;
	
						print Handle_out "$index\n";
	
						for($i = 0 ; ($i * 60) < $len ; $i ++)
						{
							$print = substr($seq_temp , ($i * 60) , 60);
	
							print Handle_out "$print\n";
						}
	
						if($len < $opts{max})
						{
							last;
						}
					}
				}
				else
				{
					print Handle_out "$original\n";
	
					for($j = 0 ; ($j * 60) < $length ; $j ++)
					{
						$print = substr($seq , ($j * 60) , 60);
	
						print Handle_out "$print\n";
					}
				}
			}
	
			$flag = 1;
	
			$original = $_;
	
			$name = $name_temp;
	
			$seq = "";
		}
		else
		{
			$seq .= $_;
		}
	}
	
	$length = length($seq);
	
	if($length > $opts{max})
	{
		for($j = 0 ; $j * ($opts{max} - $opts{overlap}) < $length ; $j ++)
		{
			$start = $j * ($opts{max} - $opts{overlap});
	
			$seq_temp = substr($seq , $start , $opts{max});
	
			$len = length($seq_temp);
	
			$index = $original;
	
			$index =~ s/$name/$name\_$length\_$start/;
	
			print Handle_out "$index\n";
	
			for($i = 0 ; ($i * 60) < $len ; $i ++)
			{
				$print = substr($seq_temp , ($i * 60) , 60);
	
				print Handle_out "$print\n";
			}
	
			if($len < $opts{max})
			{
				last;
			}
		}
	}
	else
	{
		print Handle_out "$original\n";
	
		for($j = 0 ; ($j * 60) < $length ; $j ++)
		{
			$print = substr($seq , ($j * 60) , 60);
	
			print Handle_out "$print\n";
		}
	}
	close(Handle);
	close(Handle_out);
	
	print("\n============================================================\n");
	my $Time_End = sub_format_datetime(localtime(time()));
	print "Running from [$Time_Start] to [$Time_End]\n";
	print("............................................................\n");
	
	
	exit;
	#############
}


#-------------------------------------------------------------------------------
sub sub_format_datetime #datetime subprogram
{
    my($sec , $min , $hour , $day , $mon , $year , $wday , $yday , $isdst) = @_;

    sprintf("%4d-%02d-%02d %02d:%02d:%02d" , ($year + 1900) , $mon , $day , $hour , $min , $sec);
};

#-------------------------------------------------------------------------------
sub Usage #help subprogram
{
    print << "    Usage";

	DESCRIPTION:
	
		$Function

	Version : $version

	Usage: $0 <options>

		-seq           Path/input_file , must be given (string)

		[split sequence into sequences]
		
		-overlap       [Number of overlap] (number)
		
		-max           [Maximum length of each sequence] (number)
		
		-nl            Number of sequences what you want to split one sequence into
		
		-out           Path/output_file (string)

		[split fasta file into files]
		
		-nf            used to split fasta into files, Number of files to be split.
		
		-ns            used to split fasta into files, Number of sequences into one file
		
		-od            used in split fasta into files, output directory

		[help info]
		
		-h or -help    show help , have a choice

		-i or -info    show document info with perldoc , have a choice

    Usage

	exit(0);
};

#-------------------------------------------------------------------------------
sub PrintParam
{
	print << "    EOF";

    InputValue:
    
	seq        = $opts{seq}
    
	max        = $opts{max}
    
	overlap    = $opts{overlap}

	out        = $opts{out}

    EOF
};

