#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Manacus_vitellinus.scaf.noBacterial.fa.gz > PWD/outdata/MANVI/Manacus_vitellinus.scaf.noBacterial.fa && echo gzip MANVI was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/MANVI/Manacus_vitellinus.scaf.noBacterial.fa && echo rptmd MANVI was OK 
 ln -s PWD/outdata/MANVI/result/consensi.fa.classified PWD/outdata/MANVI/final.library && echo ln -s MANVI was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/MANVI/final.library PWD/outdata/MANVI/Manacus_vitellinus.scaf.noBacterial.fa && echo denovo annotation MANVI was OK 
 perl PWD/bin/out_format.pl PWD/outdata/MANVI/Manacus_vitellinus.denovo.RepeatMasker.out > PWD/outdata/MANVI/Manacus_vitellinus.denovo.RepeatMasker.out.filter && echo filter denovo .out MANVI was OK 
 mv PWD/outdata/MANVI/Manacus_vitellinus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/MANVI/Manacus_vitellinus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/MANVI/Manacus_vitellinus.scaf.noBacterial.fa && echo repbase annotation MANVI was OK 
  perl PWD/bin/out_format.pl PWD/outdata/MANVI/Manacus_vitellinus.known.RepeatMasker.out > PWD/outdata/MANVI/Manacus_vitellinus.known.RepeatMasker.out.filter && echo filter repbase .out MANVI was OK 
 mv PWD/outdata/MANVI/Manacus_vitellinus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/MANVI/Manacus_vitellinus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  MANVI 
