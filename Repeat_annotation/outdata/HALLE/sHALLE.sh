#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Haliaeetus_leucocephalus.fa.gz > PWD/outdata/HALLE/Haliaeetus_leucocephalus.fa && echo gzip HALLE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/HALLE/Haliaeetus_leucocephalus.fa && echo rptmd HALLE was OK 
 ln -s PWD/outdata/HALLE/result/consensi.fa.classified PWD/outdata/HALLE/final.library && echo ln -s HALLE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/HALLE/final.library PWD/outdata/HALLE/Haliaeetus_leucocephalus.fa && echo denovo annotation HALLE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/HALLE/Haliaeetus_leucocephalus.denovo.RepeatMasker.out > PWD/outdata/HALLE/Haliaeetus_leucocephalus.denovo.RepeatMasker.out.filter && echo filter denovo .out HALLE was OK 
 mv PWD/outdata/HALLE/Haliaeetus_leucocephalus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/HALLE/Haliaeetus_leucocephalus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/HALLE/Haliaeetus_leucocephalus.fa && echo repbase annotation HALLE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/HALLE/Haliaeetus_leucocephalus.known.RepeatMasker.out > PWD/outdata/HALLE/Haliaeetus_leucocephalus.known.RepeatMasker.out.filter && echo filter repbase .out HALLE was OK 
 mv PWD/outdata/HALLE/Haliaeetus_leucocephalus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/HALLE/Haliaeetus_leucocephalus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  HALLE 
