#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Cathartes_aura.scaf.noBacterial.fa.gz > PWD/outdata/CATAU/Cathartes_aura.scaf.noBacterial.fa && echo gzip CATAU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CATAU/Cathartes_aura.scaf.noBacterial.fa && echo rptmd CATAU was OK 
 ln -s PWD/outdata/CATAU/result/consensi.fa.classified PWD/outdata/CATAU/final.library && echo ln -s CATAU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CATAU/final.library PWD/outdata/CATAU/Cathartes_aura.scaf.noBacterial.fa && echo denovo annotation CATAU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CATAU/Cathartes_aura.denovo.RepeatMasker.out > PWD/outdata/CATAU/Cathartes_aura.denovo.RepeatMasker.out.filter && echo filter denovo .out CATAU was OK 
 mv PWD/outdata/CATAU/Cathartes_aura.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CATAU/Cathartes_aura.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CATAU/Cathartes_aura.scaf.noBacterial.fa && echo repbase annotation CATAU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CATAU/Cathartes_aura.known.RepeatMasker.out > PWD/outdata/CATAU/Cathartes_aura.known.RepeatMasker.out.filter && echo filter repbase .out CATAU was OK 
 mv PWD/outdata/CATAU/Cathartes_aura.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CATAU/Cathartes_aura.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CATAU 
