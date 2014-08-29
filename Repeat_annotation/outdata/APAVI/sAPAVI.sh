#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Apaloderma_vittatum.scaf.noBacterial.fa.gz > PWD/outdata/APAVI/Apaloderma_vittatum.scaf.noBacterial.fa && echo gzip APAVI was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/APAVI/Apaloderma_vittatum.scaf.noBacterial.fa && echo rptmd APAVI was OK 
 ln -s PWD/outdata/APAVI/result/consensi.fa.classified PWD/outdata/APAVI/final.library && echo ln -s APAVI was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/APAVI/final.library PWD/outdata/APAVI/Apaloderma_vittatum.scaf.noBacterial.fa && echo denovo annotation APAVI was OK 
 perl PWD/bin/out_format.pl PWD/outdata/APAVI/Apaloderma_vittatum.denovo.RepeatMasker.out > PWD/outdata/APAVI/Apaloderma_vittatum.denovo.RepeatMasker.out.filter && echo filter denovo .out APAVI was OK 
 mv PWD/outdata/APAVI/Apaloderma_vittatum.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/APAVI/Apaloderma_vittatum.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/APAVI/Apaloderma_vittatum.scaf.noBacterial.fa && echo repbase annotation APAVI was OK 
  perl PWD/bin/out_format.pl PWD/outdata/APAVI/Apaloderma_vittatum.known.RepeatMasker.out > PWD/outdata/APAVI/Apaloderma_vittatum.known.RepeatMasker.out.filter && echo filter repbase .out APAVI was OK 
 mv PWD/outdata/APAVI/Apaloderma_vittatum.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/APAVI/Apaloderma_vittatum.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  APAVI 
