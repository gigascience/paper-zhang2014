#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Colius_striatus.scaf.noBacterial.fa.gz > PWD/outdata/COLST/Colius_striatus.scaf.noBacterial.fa && echo gzip COLST was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/COLST/Colius_striatus.scaf.noBacterial.fa && echo rptmd COLST was OK 
 ln -s PWD/outdata/COLST/result/consensi.fa.classified PWD/outdata/COLST/final.library && echo ln -s COLST was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/COLST/final.library PWD/outdata/COLST/Colius_striatus.scaf.noBacterial.fa && echo denovo annotation COLST was OK 
 perl PWD/bin/out_format.pl PWD/outdata/COLST/Colius_striatus.denovo.RepeatMasker.out > PWD/outdata/COLST/Colius_striatus.denovo.RepeatMasker.out.filter && echo filter denovo .out COLST was OK 
 mv PWD/outdata/COLST/Colius_striatus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/COLST/Colius_striatus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/COLST/Colius_striatus.scaf.noBacterial.fa && echo repbase annotation COLST was OK 
  perl PWD/bin/out_format.pl PWD/outdata/COLST/Colius_striatus.known.RepeatMasker.out > PWD/outdata/COLST/Colius_striatus.known.RepeatMasker.out.filter && echo filter repbase .out COLST was OK 
 mv PWD/outdata/COLST/Colius_striatus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/COLST/Colius_striatus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  COLST 
