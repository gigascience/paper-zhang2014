#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Eurypyga_helias.scaf.noBacterial.fa.gz > PWD/outdata/EURHE/Eurypyga_helias.scaf.noBacterial.fa && echo gzip EURHE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/EURHE/Eurypyga_helias.scaf.noBacterial.fa && echo rptmd EURHE was OK 
 ln -s PWD/outdata/EURHE/result/consensi.fa.classified PWD/outdata/EURHE/final.library && echo ln -s EURHE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/EURHE/final.library PWD/outdata/EURHE/Eurypyga_helias.scaf.noBacterial.fa && echo denovo annotation EURHE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/EURHE/Eurypyga_helias.denovo.RepeatMasker.out > PWD/outdata/EURHE/Eurypyga_helias.denovo.RepeatMasker.out.filter && echo filter denovo .out EURHE was OK 
 mv PWD/outdata/EURHE/Eurypyga_helias.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/EURHE/Eurypyga_helias.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/EURHE/Eurypyga_helias.scaf.noBacterial.fa && echo repbase annotation EURHE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/EURHE/Eurypyga_helias.known.RepeatMasker.out > PWD/outdata/EURHE/Eurypyga_helias.known.RepeatMasker.out.filter && echo filter repbase .out EURHE was OK 
 mv PWD/outdata/EURHE/Eurypyga_helias.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/EURHE/Eurypyga_helias.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  EURHE 
