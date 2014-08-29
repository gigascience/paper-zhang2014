#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Tauraco_erythrolophus.scaf.noBacterial.fa.gz > PWD/outdata/TAUER/Tauraco_erythrolophus.scaf.noBacterial.fa && echo gzip TAUER was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/TAUER/Tauraco_erythrolophus.scaf.noBacterial.fa && echo rptmd TAUER was OK 
 ln -s PWD/outdata/TAUER/result/consensi.fa.classified PWD/outdata/TAUER/final.library && echo ln -s TAUER was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/TAUER/final.library PWD/outdata/TAUER/Tauraco_erythrolophus.scaf.noBacterial.fa && echo denovo annotation TAUER was OK 
 perl PWD/bin/out_format.pl PWD/outdata/TAUER/Tauraco_erythrolophus.denovo.RepeatMasker.out > PWD/outdata/TAUER/Tauraco_erythrolophus.denovo.RepeatMasker.out.filter && echo filter denovo .out TAUER was OK 
 mv PWD/outdata/TAUER/Tauraco_erythrolophus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/TAUER/Tauraco_erythrolophus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/TAUER/Tauraco_erythrolophus.scaf.noBacterial.fa && echo repbase annotation TAUER was OK 
  perl PWD/bin/out_format.pl PWD/outdata/TAUER/Tauraco_erythrolophus.known.RepeatMasker.out > PWD/outdata/TAUER/Tauraco_erythrolophus.known.RepeatMasker.out.filter && echo filter repbase .out TAUER was OK 
 mv PWD/outdata/TAUER/Tauraco_erythrolophus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/TAUER/Tauraco_erythrolophus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  TAUER 
