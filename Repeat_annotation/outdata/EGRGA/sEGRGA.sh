#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Egretta_garzetta.scaf.noBacterial.fa.gz > PWD/outdata/EGRGA/Egretta_garzetta.scaf.noBacterial.fa && echo gzip EGRGA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/EGRGA/Egretta_garzetta.scaf.noBacterial.fa && echo rptmd EGRGA was OK 
 ln -s PWD/outdata/EGRGA/result/consensi.fa.classified PWD/outdata/EGRGA/final.library && echo ln -s EGRGA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/EGRGA/final.library PWD/outdata/EGRGA/Egretta_garzetta.scaf.noBacterial.fa && echo denovo annotation EGRGA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/EGRGA/Egretta_garzetta.denovo.RepeatMasker.out > PWD/outdata/EGRGA/Egretta_garzetta.denovo.RepeatMasker.out.filter && echo filter denovo .out EGRGA was OK 
 mv PWD/outdata/EGRGA/Egretta_garzetta.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/EGRGA/Egretta_garzetta.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/EGRGA/Egretta_garzetta.scaf.noBacterial.fa && echo repbase annotation EGRGA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/EGRGA/Egretta_garzetta.known.RepeatMasker.out > PWD/outdata/EGRGA/Egretta_garzetta.known.RepeatMasker.out.filter && echo filter repbase .out EGRGA was OK 
 mv PWD/outdata/EGRGA/Egretta_garzetta.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/EGRGA/Egretta_garzetta.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  EGRGA 
