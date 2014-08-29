#!/bin/bash

if [ $# -lt 1 ]
then
echo "sh $0 <dir: ./>"
exit 0
fi

cat ../GALGA/*.orth.gff.nr.gff ../TAEGU/*.orth.gff.nr.gff > tae_gal.orth.gff
cat ../GALGA/*.para.gff.nr.gff ../TAEGU/*.para.gff.nr.gff > tae_gal.para.gff

## Clustgff*.pl were used to merge redundant gene models.
perl ../bin/clustergff.shell.pl tae_gal.orth.gff  ENSGALT --cpu 5
perl  ../bin/clustergff.pl.new.pl tae_gal.para.gff multi 100 10
cat tae_gal.para.gff.nr.gff tae_gal.orth.gff.nr.gff > tae_gal.gff
perl  ../bin/clustergff_orthPara.shell.pl tae_gal.gff tae_gal.orth.gff.nr.gff tae_gal.para.gff.nr.gff --cpu 10 

## Genes whose identity < 40 were removed.
cat ../HUMAN/*ident40.PF.gff.nr.gff tae_gal.gff.nr.gff > tae_gal_hg.gff
perl ../bin/clustergff.shell.pl tae_gal_hg.gff ENST0 --cpu 8 
perl  ../bin/combine_filter_sh.pl ./

