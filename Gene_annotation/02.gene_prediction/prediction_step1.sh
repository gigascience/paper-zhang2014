## protein sequences were mapped to DNA sequences. Blast and Genewise were used. 'genome.dna.fa' represents the genome assembly for a specific bird. Please note that this command line submitted parallel jobs to BGI Linux cluster.
perl ../bin/v8.1_protein_map_genome.pl --verbose --cpu 50 --resource vf=1G --run qsub --blast_eval 1e-5 --filter_rate 0.5 --extend_len 2000 --step 12346 --lines 500 --rgene Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff --reqsub Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep genome.dna.fa

## Find genes predicted through chicken genes (in chicken-finch orthologs).
perl ../bin/fishInWinter.pl -fc 2 gal_tae.ref2.gal Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.filter.gff.ident.list.filter > Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.filter.gff.ident.list.filter.gal

## Percent identities were estimated from MUSCLE alignment result.
perl ../bin/algnRat2identity_gff.pl Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.filter.gff.ident.list.filter.gal Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.gff > Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.gff.ident

## Remove pseudogenes.
perl ../bin/pseudogene_filter.pl Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.gff.ident Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.filter.gff.cds.gz > Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.gff.ident.PF.gff 2> Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.filter.gff.ident.pseudo.gff

## Generete non-redundant gene set.
perl ../bin/clustergff.pl.new.pl Gallus_gallus.WASHUC2.60.gtf.mRNA.clean.gff.cds.pep.genblast.genewise.gff.ident.PF.gff  multi 100 5

