#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Chaetura_pelagica.scaf.noBacterial.fa.gz > PWD/outdata/CHAPE/Chaetura_pelagica.scaf.noBacterial.fa && echo gzip CHAPE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CHAPE/Chaetura_pelagica.scaf.noBacterial.fa && echo rptmd CHAPE was OK 
 ln -s PWD/outdata/CHAPE/result/consensi.fa.classified PWD/outdata/CHAPE/final.library && echo ln -s CHAPE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CHAPE/final.library PWD/outdata/CHAPE/Chaetura_pelagica.scaf.noBacterial.fa && echo denovo annotation CHAPE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CHAPE/Chaetura_pelagica.denovo.RepeatMasker.out > PWD/outdata/CHAPE/Chaetura_pelagica.denovo.RepeatMasker.out.filter && echo filter denovo .out CHAPE was OK 
 mv PWD/outdata/CHAPE/Chaetura_pelagica.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CHAPE/Chaetura_pelagica.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CHAPE/Chaetura_pelagica.scaf.noBacterial.fa && echo repbase annotation CHAPE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CHAPE/Chaetura_pelagica.known.RepeatMasker.out > PWD/outdata/CHAPE/Chaetura_pelagica.known.RepeatMasker.out.filter && echo filter repbase .out CHAPE was OK 
 mv PWD/outdata/CHAPE/Chaetura_pelagica.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CHAPE/Chaetura_pelagica.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CHAPE 
