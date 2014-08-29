#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Nipponia_nippon.scaf.fa.gz > PWD/outdata/NIPNI/Nipponia_nippon.scaf.fa && echo gzip NIPNI was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/NIPNI/Nipponia_nippon.scaf.fa && echo rptmd NIPNI was OK 
 ln -s PWD/outdata/NIPNI/result/consensi.fa.classified PWD/outdata/NIPNI/final.library && echo ln -s NIPNI was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/NIPNI/final.library PWD/outdata/NIPNI/Nipponia_nippon.scaf.fa && echo denovo annotation NIPNI was OK 
 perl PWD/bin/out_format.pl PWD/outdata/NIPNI/Nipponia_nippon.denovo.RepeatMasker.out > PWD/outdata/NIPNI/Nipponia_nippon.denovo.RepeatMasker.out.filter && echo filter denovo .out NIPNI was OK 
 mv PWD/outdata/NIPNI/Nipponia_nippon.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/NIPNI/Nipponia_nippon.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/NIPNI/Nipponia_nippon.scaf.fa && echo repbase annotation NIPNI was OK 
  perl PWD/bin/out_format.pl PWD/outdata/NIPNI/Nipponia_nippon.known.RepeatMasker.out > PWD/outdata/NIPNI/Nipponia_nippon.known.RepeatMasker.out.filter && echo filter repbase .out NIPNI was OK 
 mv PWD/outdata/NIPNI/Nipponia_nippon.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/NIPNI/Nipponia_nippon.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  NIPNI 
