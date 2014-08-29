#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Falco_peregrinus.scaf.fa.gz > PWD/outdata/FALPE/Falco_peregrinus.scaf.fa && echo gzip FALPE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/FALPE/Falco_peregrinus.scaf.fa && echo rptmd FALPE was OK 
 ln -s PWD/outdata/FALPE/result/consensi.fa.classified PWD/outdata/FALPE/final.library && echo ln -s FALPE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/FALPE/final.library PWD/outdata/FALPE/Falco_peregrinus.scaf.fa && echo denovo annotation FALPE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/FALPE/Falco_peregrinus.denovo.RepeatMasker.out > PWD/outdata/FALPE/Falco_peregrinus.denovo.RepeatMasker.out.filter && echo filter denovo .out FALPE was OK 
 mv PWD/outdata/FALPE/Falco_peregrinus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/FALPE/Falco_peregrinus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/FALPE/Falco_peregrinus.scaf.fa && echo repbase annotation FALPE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/FALPE/Falco_peregrinus.known.RepeatMasker.out > PWD/outdata/FALPE/Falco_peregrinus.known.RepeatMasker.out.filter && echo filter repbase .out FALPE was OK 
 mv PWD/outdata/FALPE/Falco_peregrinus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/FALPE/Falco_peregrinus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  FALPE 
