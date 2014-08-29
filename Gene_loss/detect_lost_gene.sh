##Get the predicted genes in each outgroup and bird for each human gene. 
perl bin/human_birds_gene.pl gff_improve/highQ gff_improve/lowQ raw human.best.ann.disease human.list.gtf.filter.pep >human.birds.best.mut

##Get the lost genes in avian genomes.
perl bin/get_loss_gene.pl human.birds.best.mut 50 ancestor.gene >human.birds.best.mut.lost

##Change the format of lost genes.
perl bin/change_best_format.pl human.birds.best.mut.lost >human.birds.best.mut.lost.txt
