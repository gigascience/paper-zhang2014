#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Balearica_regulorum_gibbericeps.scaf.noBacterial.fa.gz > PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.scaf.noBacterial.fa && echo gzip BALRE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.scaf.noBacterial.fa && echo rptmd BALRE was OK 
 ln -s PWD/outdata/BALRE/result/consensi.fa.classified PWD/outdata/BALRE/final.library && echo ln -s BALRE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/BALRE/final.library PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.scaf.noBacterial.fa && echo denovo annotation BALRE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.denovo.RepeatMasker.out > PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.denovo.RepeatMasker.out.filter && echo filter denovo .out BALRE was OK 
 mv PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.scaf.noBacterial.fa && echo repbase annotation BALRE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.known.RepeatMasker.out > PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.known.RepeatMasker.out.filter && echo filter repbase .out BALRE was OK 
 mv PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/BALRE/Balearica_regulorum_gibbericeps.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  BALRE 
