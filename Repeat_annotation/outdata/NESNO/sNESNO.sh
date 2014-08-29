#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Nestor_notabilis.scaf.noBacterial.fa.gz > PWD/outdata/NESNO/Nestor_notabilis.scaf.noBacterial.fa && echo gzip NESNO was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/NESNO/Nestor_notabilis.scaf.noBacterial.fa && echo rptmd NESNO was OK 
 ln -s PWD/outdata/NESNO/result/consensi.fa.classified PWD/outdata/NESNO/final.library && echo ln -s NESNO was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/NESNO/final.library PWD/outdata/NESNO/Nestor_notabilis.scaf.noBacterial.fa && echo denovo annotation NESNO was OK 
 perl PWD/bin/out_format.pl PWD/outdata/NESNO/Nestor_notabilis.denovo.RepeatMasker.out > PWD/outdata/NESNO/Nestor_notabilis.denovo.RepeatMasker.out.filter && echo filter denovo .out NESNO was OK 
 mv PWD/outdata/NESNO/Nestor_notabilis.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/NESNO/Nestor_notabilis.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/NESNO/Nestor_notabilis.scaf.noBacterial.fa && echo repbase annotation NESNO was OK 
  perl PWD/bin/out_format.pl PWD/outdata/NESNO/Nestor_notabilis.known.RepeatMasker.out > PWD/outdata/NESNO/Nestor_notabilis.known.RepeatMasker.out.filter && echo filter repbase .out NESNO was OK 
 mv PWD/outdata/NESNO/Nestor_notabilis.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/NESNO/Nestor_notabilis.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  NESNO 
