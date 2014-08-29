#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Corvus_brachyrhynchos.scaf.noBacterial.fa.gz > PWD/outdata/CORBR/Corvus_brachyrhynchos.scaf.noBacterial.fa && echo gzip CORBR was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CORBR/Corvus_brachyrhynchos.scaf.noBacterial.fa && echo rptmd CORBR was OK 
 ln -s PWD/outdata/CORBR/result/consensi.fa.classified PWD/outdata/CORBR/final.library && echo ln -s CORBR was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CORBR/final.library PWD/outdata/CORBR/Corvus_brachyrhynchos.scaf.noBacterial.fa && echo denovo annotation CORBR was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CORBR/Corvus_brachyrhynchos.denovo.RepeatMasker.out > PWD/outdata/CORBR/Corvus_brachyrhynchos.denovo.RepeatMasker.out.filter && echo filter denovo .out CORBR was OK 
 mv PWD/outdata/CORBR/Corvus_brachyrhynchos.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CORBR/Corvus_brachyrhynchos.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CORBR/Corvus_brachyrhynchos.scaf.noBacterial.fa && echo repbase annotation CORBR was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CORBR/Corvus_brachyrhynchos.known.RepeatMasker.out > PWD/outdata/CORBR/Corvus_brachyrhynchos.known.RepeatMasker.out.filter && echo filter repbase .out CORBR was OK 
 mv PWD/outdata/CORBR/Corvus_brachyrhynchos.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CORBR/Corvus_brachyrhynchos.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CORBR 
