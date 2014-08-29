##The following 3 command lines must run one by one, that is you must confirm prior job finished and then run the next.

##Note: In bin/call_blast.pl which is called by bin/blast_to_pep.pl, the line 28 is for submitting jods to your computer clusters, modify it according to your computing environment.
##Note: In bin/blast_to_pep.pl, the line 66 is for submitting jods to your computer clusters, modify it according to your computing environment.
perl bin/blast_to_pep.pl nr/highQ human.list.gtf.filter.pep 50 nr/highQ/blastToPEP 1
perl bin/blast_to_pep.pl nr/highQ human.list.gtf.filter.pep 50 nr/highQ/blastToPEP 2

##Note: In bin/improve_gff_file_shell.pl, the line 34 is for submitting jods to your computer clusters, modify it according to your computing environment.
perl bin/improve_gff_file_shell.pl nr/highQ homo_sapiens.60.ann.gz gff_improve/highQ
