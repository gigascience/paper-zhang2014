##Note: In bin/dealHomologPredictHQ.pl which is called by bin/homologPredict_nr_shell.pl, the line 67 is for submitting jods to your computer clusters, modify it according to your computing environment.
perl bin/homologPredict_nr_shell.pl outgroups_name.txt human.list.gtf.filter.gff raw genome nr/highQ --q high

