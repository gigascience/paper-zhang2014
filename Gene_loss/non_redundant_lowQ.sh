##Note: In bin/dealHomologPredictLQ.pl which is called by bin/homologPredict_nr_shell.pl, the line 65 is for submitting jods to your computer clusters, modify it according to your computing environment.
perl bin/homologPredict_nr_shell.pl bird_name.txt human.list.gtf.filter.gff raw genome nr/lowQ --q low
