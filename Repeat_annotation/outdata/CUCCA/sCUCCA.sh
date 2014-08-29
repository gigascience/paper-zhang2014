#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Cuculus_canorus.scaf.noBacterial.fa.gz > PWD/outdata/CUCCA/Cuculus_canorus.scaf.noBacterial.fa && echo gzip CUCCA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CUCCA/Cuculus_canorus.scaf.noBacterial.fa && echo rptmd CUCCA was OK 
 ln -s PWD/outdata/CUCCA/result/consensi.fa.classified PWD/outdata/CUCCA/final.library && echo ln -s CUCCA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CUCCA/final.library PWD/outdata/CUCCA/Cuculus_canorus.scaf.noBacterial.fa && echo denovo annotation CUCCA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CUCCA/Cuculus_canorus.denovo.RepeatMasker.out > PWD/outdata/CUCCA/Cuculus_canorus.denovo.RepeatMasker.out.filter && echo filter denovo .out CUCCA was OK 
 mv PWD/outdata/CUCCA/Cuculus_canorus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CUCCA/Cuculus_canorus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CUCCA/Cuculus_canorus.scaf.noBacterial.fa && echo repbase annotation CUCCA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CUCCA/Cuculus_canorus.known.RepeatMasker.out > PWD/outdata/CUCCA/Cuculus_canorus.known.RepeatMasker.out.filter && echo filter repbase .out CUCCA was OK 
 mv PWD/outdata/CUCCA/Cuculus_canorus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CUCCA/Cuculus_canorus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CUCCA 
