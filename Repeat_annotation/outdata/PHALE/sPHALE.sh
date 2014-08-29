#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Phaethon_lepturus.scaf.noBacterial.fa.gz > PWD/outdata/PHALE/Phaethon_lepturus.scaf.noBacterial.fa && echo gzip PHALE was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PHALE/Phaethon_lepturus.scaf.noBacterial.fa && echo rptmd PHALE was OK 
 ln -s PWD/outdata/PHALE/result/consensi.fa.classified PWD/outdata/PHALE/final.library && echo ln -s PHALE was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PHALE/final.library PWD/outdata/PHALE/Phaethon_lepturus.scaf.noBacterial.fa && echo denovo annotation PHALE was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PHALE/Phaethon_lepturus.denovo.RepeatMasker.out > PWD/outdata/PHALE/Phaethon_lepturus.denovo.RepeatMasker.out.filter && echo filter denovo .out PHALE was OK 
 mv PWD/outdata/PHALE/Phaethon_lepturus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PHALE/Phaethon_lepturus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PHALE/Phaethon_lepturus.scaf.noBacterial.fa && echo repbase annotation PHALE was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PHALE/Phaethon_lepturus.known.RepeatMasker.out > PWD/outdata/PHALE/Phaethon_lepturus.known.RepeatMasker.out.filter && echo filter repbase .out PHALE was OK 
 mv PWD/outdata/PHALE/Phaethon_lepturus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PHALE/Phaethon_lepturus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PHALE 
