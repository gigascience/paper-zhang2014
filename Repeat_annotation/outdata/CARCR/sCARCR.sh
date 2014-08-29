#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Cariama_cristata.scaf.noBacterial.fa.gz > PWD/outdata/CARCR/Cariama_cristata.scaf.noBacterial.fa && echo gzip CARCR was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CARCR/Cariama_cristata.scaf.noBacterial.fa && echo rptmd CARCR was OK 
 ln -s PWD/outdata/CARCR/result/consensi.fa.classified PWD/outdata/CARCR/final.library && echo ln -s CARCR was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CARCR/final.library PWD/outdata/CARCR/Cariama_cristata.scaf.noBacterial.fa && echo denovo annotation CARCR was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CARCR/Cariama_cristata.denovo.RepeatMasker.out > PWD/outdata/CARCR/Cariama_cristata.denovo.RepeatMasker.out.filter && echo filter denovo .out CARCR was OK 
 mv PWD/outdata/CARCR/Cariama_cristata.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CARCR/Cariama_cristata.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CARCR/Cariama_cristata.scaf.noBacterial.fa && echo repbase annotation CARCR was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CARCR/Cariama_cristata.known.RepeatMasker.out > PWD/outdata/CARCR/Cariama_cristata.known.RepeatMasker.out.filter && echo filter repbase .out CARCR was OK 
 mv PWD/outdata/CARCR/Cariama_cristata.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CARCR/Cariama_cristata.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CARCR 
