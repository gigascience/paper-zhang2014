#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Caprimugus_Carolinensis.scaf.noBacterial.fa.gz > PWD/outdata/CAPCA/Caprimugus_Carolinensis.scaf.noBacterial.fa && echo gzip CAPCA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CAPCA/Caprimugus_Carolinensis.scaf.noBacterial.fa && echo rptmd CAPCA was OK 
 ln -s PWD/outdata/CAPCA/result/consensi.fa.classified PWD/outdata/CAPCA/final.library && echo ln -s CAPCA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CAPCA/final.library PWD/outdata/CAPCA/Caprimugus_Carolinensis.scaf.noBacterial.fa && echo denovo annotation CAPCA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CAPCA/Caprimugus_Carolinensis.denovo.RepeatMasker.out > PWD/outdata/CAPCA/Caprimugus_Carolinensis.denovo.RepeatMasker.out.filter && echo filter denovo .out CAPCA was OK 
 mv PWD/outdata/CAPCA/Caprimugus_Carolinensis.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CAPCA/Caprimugus_Carolinensis.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CAPCA/Caprimugus_Carolinensis.scaf.noBacterial.fa && echo repbase annotation CAPCA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CAPCA/Caprimugus_Carolinensis.known.RepeatMasker.out > PWD/outdata/CAPCA/Caprimugus_Carolinensis.known.RepeatMasker.out.filter && echo filter repbase .out CAPCA was OK 
 mv PWD/outdata/CAPCA/Caprimugus_Carolinensis.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CAPCA/Caprimugus_Carolinensis.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CAPCA 
