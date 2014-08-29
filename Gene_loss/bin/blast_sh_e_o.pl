#!/usr/bin/perl -w
use strict;
use File::Basename;

die "Usage: <in_dir>!\n" unless @ARGV == 1;
my $in_dir = shift;

my $sum;
my %hash;
opendir DH, $in_dir;
while (my $file = readdir DH) {
	if ($file =~ /\.sh\.e/) {
		open IN, "$in_dir/$file";
		while (<IN>) {
			chomp;
			if ($_ && $_ !~/^Selenocysteine \(U\) at position \d+ replaced by X$/) {
				print "$in_dir/$file\n";
				last;
			}
		}
		close IN;
	} elsif ($file =~ /\.sh\.o/) {
		$sum ++;
		my $num = 0;
		my $name = (split /\./, $file)[0];
		$hash{$name} ++;
		die "$in_dir/$name\n" if ($hash{$name} > 1);
		open IN, "$in_dir/$file";
		while (<IN>) {
			chomp;
			$num ++;
			unless (/^\w+ \w+\s+\S+ \d+:\d+:\d+ \w+ \d+$/) {
				print "$in_dir/$file\n";
				last;
			}
		}
		close IN;
		unless ($num == 2) {
			print "$in_dir/$file\n";
		}
	}
}
closedir DH;

print "$sum\n";
