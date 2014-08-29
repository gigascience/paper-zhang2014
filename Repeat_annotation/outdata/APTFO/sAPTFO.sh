#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Aptenodytes_forsteri.scaf.fa.gz > PWD/outdata/APTFO/Aptenodytes_forsteri.scaf.fa && echo gzip APTFO was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/APTFO/Aptenodytes_forsteri.scaf.fa && echo rptmd APTFO was OK 
 ln -s PWD/outdata/APTFO/result/consensi.fa.classified PWD/outdata/APTFO/final.library && echo ln -s APTFO was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/APTFO/final.library PWD/outdata/APTFO/Aptenodytes_forsteri.scaf.fa && echo denovo annotation APTFO was OK 
 perl PWD/bin/out_format.pl PWD/outdata/APTFO/Aptenodytes_forsteri.denovo.RepeatMasker.out > PWD/outdata/APTFO/Aptenodytes_forsteri.denovo.RepeatMasker.out.filter && echo filter denovo .out APTFO was OK 
 mv PWD/outdata/APTFO/Aptenodytes_forsteri.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/APTFO/Aptenodytes_forsteri.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/APTFO/Aptenodytes_forsteri.scaf.fa && echo repbase annotation APTFO was OK 
  perl PWD/bin/out_format.pl PWD/outdata/APTFO/Aptenodytes_forsteri.known.RepeatMasker.out > PWD/outdata/APTFO/Aptenodytes_forsteri.known.RepeatMasker.out.filter && echo filter repbase .out APTFO was OK 
 mv PWD/outdata/APTFO/Aptenodytes_forsteri.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/APTFO/Aptenodytes_forsteri.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  APTFO 
