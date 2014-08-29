#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Picoides_pubescens.scaf.noBacterial.fa.gz > PWD/outdata/PICPU/Picoides_pubescens.scaf.noBacterial.fa && echo gzip PICPU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PICPU/Picoides_pubescens.scaf.noBacterial.fa && echo rptmd PICPU was OK 
 ln -s PWD/outdata/PICPU/result/consensi.fa.classified PWD/outdata/PICPU/final.library && echo ln -s PICPU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PICPU/final.library PWD/outdata/PICPU/Picoides_pubescens.scaf.noBacterial.fa && echo denovo annotation PICPU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PICPU/Picoides_pubescens.denovo.RepeatMasker.out > PWD/outdata/PICPU/Picoides_pubescens.denovo.RepeatMasker.out.filter && echo filter denovo .out PICPU was OK 
 mv PWD/outdata/PICPU/Picoides_pubescens.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PICPU/Picoides_pubescens.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PICPU/Picoides_pubescens.scaf.noBacterial.fa && echo repbase annotation PICPU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PICPU/Picoides_pubescens.known.RepeatMasker.out > PWD/outdata/PICPU/Picoides_pubescens.known.RepeatMasker.out.filter && echo filter repbase .out PICPU was OK 
 mv PWD/outdata/PICPU/Picoides_pubescens.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PICPU/Picoides_pubescens.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PICPU 
