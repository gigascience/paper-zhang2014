#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Tinamus_major.scaf.noBacterial.fa.gz > PWD/outdata/TINMA/Tinamus_major.scaf.noBacterial.fa && echo gzip TINMA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/TINMA/Tinamus_major.scaf.noBacterial.fa && echo rptmd TINMA was OK 
 ln -s PWD/outdata/TINMA/result/consensi.fa.classified PWD/outdata/TINMA/final.library && echo ln -s TINMA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/TINMA/final.library PWD/outdata/TINMA/Tinamus_major.scaf.noBacterial.fa && echo denovo annotation TINMA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/TINMA/Tinamus_major.denovo.RepeatMasker.out > PWD/outdata/TINMA/Tinamus_major.denovo.RepeatMasker.out.filter && echo filter denovo .out TINMA was OK 
 mv PWD/outdata/TINMA/Tinamus_major.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/TINMA/Tinamus_major.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/TINMA/Tinamus_major.scaf.noBacterial.fa && echo repbase annotation TINMA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/TINMA/Tinamus_major.known.RepeatMasker.out > PWD/outdata/TINMA/Tinamus_major.known.RepeatMasker.out.filter && echo filter repbase .out TINMA was OK 
 mv PWD/outdata/TINMA/Tinamus_major.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/TINMA/Tinamus_major.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  TINMA 
