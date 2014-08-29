#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Charadrius_vociferus.scaf.noBacterial.fa.gz > PWD/outdata/CHAVO/Charadrius_vociferus.scaf.noBacterial.fa && echo gzip CHAVO was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CHAVO/Charadrius_vociferus.scaf.noBacterial.fa && echo rptmd CHAVO was OK 
 ln -s PWD/outdata/CHAVO/result/consensi.fa.classified PWD/outdata/CHAVO/final.library && echo ln -s CHAVO was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CHAVO/final.library PWD/outdata/CHAVO/Charadrius_vociferus.scaf.noBacterial.fa && echo denovo annotation CHAVO was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CHAVO/Charadrius_vociferus.denovo.RepeatMasker.out > PWD/outdata/CHAVO/Charadrius_vociferus.denovo.RepeatMasker.out.filter && echo filter denovo .out CHAVO was OK 
 mv PWD/outdata/CHAVO/Charadrius_vociferus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CHAVO/Charadrius_vociferus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CHAVO/Charadrius_vociferus.scaf.noBacterial.fa && echo repbase annotation CHAVO was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CHAVO/Charadrius_vociferus.known.RepeatMasker.out > PWD/outdata/CHAVO/Charadrius_vociferus.known.RepeatMasker.out.filter && echo filter repbase .out CHAVO was OK 
 mv PWD/outdata/CHAVO/Charadrius_vociferus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CHAVO/Charadrius_vociferus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CHAVO 
