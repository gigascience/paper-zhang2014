#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Podiceps_cristatus.scaf.noBacterial.fa.gz > PWD/outdata/PODCR/Podiceps_cristatus.scaf.noBacterial.fa && echo gzip PODCR was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PODCR/Podiceps_cristatus.scaf.noBacterial.fa && echo rptmd PODCR was OK 
 ln -s PWD/outdata/PODCR/result/consensi.fa.classified PWD/outdata/PODCR/final.library && echo ln -s PODCR was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PODCR/final.library PWD/outdata/PODCR/Podiceps_cristatus.scaf.noBacterial.fa && echo denovo annotation PODCR was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PODCR/Podiceps_cristatus.denovo.RepeatMasker.out > PWD/outdata/PODCR/Podiceps_cristatus.denovo.RepeatMasker.out.filter && echo filter denovo .out PODCR was OK 
 mv PWD/outdata/PODCR/Podiceps_cristatus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PODCR/Podiceps_cristatus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PODCR/Podiceps_cristatus.scaf.noBacterial.fa && echo repbase annotation PODCR was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PODCR/Podiceps_cristatus.known.RepeatMasker.out > PWD/outdata/PODCR/Podiceps_cristatus.known.RepeatMasker.out.filter && echo filter repbase .out PODCR was OK 
 mv PWD/outdata/PODCR/Podiceps_cristatus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PODCR/Podiceps_cristatus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PODCR 
