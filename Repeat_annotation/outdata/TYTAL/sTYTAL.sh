#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Tyto_alba.scaf.noBacterial.fa.gz > PWD/outdata/TYTAL/Tyto_alba.scaf.noBacterial.fa && echo gzip TYTAL was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/TYTAL/Tyto_alba.scaf.noBacterial.fa && echo rptmd TYTAL was OK 
 ln -s PWD/outdata/TYTAL/result/consensi.fa.classified PWD/outdata/TYTAL/final.library && echo ln -s TYTAL was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/TYTAL/final.library PWD/outdata/TYTAL/Tyto_alba.scaf.noBacterial.fa && echo denovo annotation TYTAL was OK 
 perl PWD/bin/out_format.pl PWD/outdata/TYTAL/Tyto_alba.denovo.RepeatMasker.out > PWD/outdata/TYTAL/Tyto_alba.denovo.RepeatMasker.out.filter && echo filter denovo .out TYTAL was OK 
 mv PWD/outdata/TYTAL/Tyto_alba.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/TYTAL/Tyto_alba.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/TYTAL/Tyto_alba.scaf.noBacterial.fa && echo repbase annotation TYTAL was OK 
  perl PWD/bin/out_format.pl PWD/outdata/TYTAL/Tyto_alba.known.RepeatMasker.out > PWD/outdata/TYTAL/Tyto_alba.known.RepeatMasker.out.filter && echo filter repbase .out TYTAL was OK 
 mv PWD/outdata/TYTAL/Tyto_alba.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/TYTAL/Tyto_alba.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  TYTAL 
