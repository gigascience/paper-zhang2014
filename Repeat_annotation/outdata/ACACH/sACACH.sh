#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Acanthisitta_chloris.scaf.noBacterial.fa.gz > PWD/outdata/ACACH/Acanthisitta_chloris.scaf.noBacterial.fa && echo gzip ACACH was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/ACACH/Acanthisitta_chloris.scaf.noBacterial.fa && echo rptmd ACACH was OK 
 ln -s PWD/outdata/ACACH/result/consensi.fa.classified PWD/outdata/ACACH/final.library && echo ln -s ACACH was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/ACACH/final.library PWD/outdata/ACACH/Acanthisitta_chloris.scaf.noBacterial.fa && echo denovo annotation ACACH was OK 
 perl PWD/bin/out_format.pl PWD/outdata/ACACH/Acanthisitta_chloris.denovo.RepeatMasker.out > PWD/outdata/ACACH/Acanthisitta_chloris.denovo.RepeatMasker.out.filter && echo filter denovo .out ACACH was OK 
 mv PWD/outdata/ACACH/Acanthisitta_chloris.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/ACACH/Acanthisitta_chloris.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/ACACH/Acanthisitta_chloris.scaf.noBacterial.fa && echo repbase annotation ACACH was OK 
  perl PWD/bin/out_format.pl PWD/outdata/ACACH/Acanthisitta_chloris.known.RepeatMasker.out > PWD/outdata/ACACH/Acanthisitta_chloris.known.RepeatMasker.out.filter && echo filter repbase .out ACACH was OK 
 mv PWD/outdata/ACACH/Acanthisitta_chloris.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/ACACH/Acanthisitta_chloris.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  ACACH 
