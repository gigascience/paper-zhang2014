#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Calypte_anna.scaf.noBacterial.fa.gz > PWD/outdata/CALAN/Calypte_anna.scaf.noBacterial.fa && echo gzip CALAN was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CALAN/Calypte_anna.scaf.noBacterial.fa && echo rptmd CALAN was OK 
 ln -s PWD/outdata/CALAN/result/consensi.fa.classified PWD/outdata/CALAN/final.library && echo ln -s CALAN was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CALAN/final.library PWD/outdata/CALAN/Calypte_anna.scaf.noBacterial.fa && echo denovo annotation CALAN was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CALAN/Calypte_anna.denovo.RepeatMasker.out > PWD/outdata/CALAN/Calypte_anna.denovo.RepeatMasker.out.filter && echo filter denovo .out CALAN was OK 
 mv PWD/outdata/CALAN/Calypte_anna.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CALAN/Calypte_anna.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CALAN/Calypte_anna.scaf.noBacterial.fa && echo repbase annotation CALAN was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CALAN/Calypte_anna.known.RepeatMasker.out > PWD/outdata/CALAN/Calypte_anna.known.RepeatMasker.out.filter && echo filter repbase .out CALAN was OK 
 mv PWD/outdata/CALAN/Calypte_anna.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CALAN/Calypte_anna.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CALAN 
