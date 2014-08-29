#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Fulmarus_glacialis.scaf.noBacterial.fa.gz > PWD/outdata/FULGL/Fulmarus_glacialis.scaf.noBacterial.fa && echo gzip FULGL was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/FULGL/Fulmarus_glacialis.scaf.noBacterial.fa && echo rptmd FULGL was OK 
 ln -s PWD/outdata/FULGL/result/consensi.fa.classified PWD/outdata/FULGL/final.library && echo ln -s FULGL was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/FULGL/final.library PWD/outdata/FULGL/Fulmarus_glacialis.scaf.noBacterial.fa && echo denovo annotation FULGL was OK 
 perl PWD/bin/out_format.pl PWD/outdata/FULGL/Fulmarus_glacialis.denovo.RepeatMasker.out > PWD/outdata/FULGL/Fulmarus_glacialis.denovo.RepeatMasker.out.filter && echo filter denovo .out FULGL was OK 
 mv PWD/outdata/FULGL/Fulmarus_glacialis.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/FULGL/Fulmarus_glacialis.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/FULGL/Fulmarus_glacialis.scaf.noBacterial.fa && echo repbase annotation FULGL was OK 
  perl PWD/bin/out_format.pl PWD/outdata/FULGL/Fulmarus_glacialis.known.RepeatMasker.out > PWD/outdata/FULGL/Fulmarus_glacialis.known.RepeatMasker.out.filter && echo filter repbase .out FULGL was OK 
 mv PWD/outdata/FULGL/Fulmarus_glacialis.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/FULGL/Fulmarus_glacialis.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  FULGL 
