#This package contains the most frequently used subroutines
#Contact Fan wei, fanw@genomics.org.cn
#Created on 2006-9-20

package  GACP;
use strict qw(subs refs);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(  
 parse_config
);


##parse the software.config file, and check the existence of each software
####################################################
sub parse_config{
        my $config_file = shift;
        my $config_name = shift;
        my $config_path;

        open IN,$config_file || die "fail open: $config_file";
        while (<IN>) {
                next if(/^\s*\#/);
				if (/(\S+)\s*=\s*(\S+)/) {
					my ($software_name,$software_address) = ($1,$2);
                    if ($config_name eq $1) {
						$config_path = $2;
						last;
					}  
                }
        }
        close IN;
		
		if ($config_path) {
			if (-e $config_path) {
				return $config_path;
			}else{
				die "\nConfig Error: $config_name wrong path in $config_file\n";
			}
		}else{
			die "\nConfig Error: $config_name not set in $config_file\n";
		}

}


1;

__END__


