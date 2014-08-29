#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Phalacrocorax_carbo.scaf.noBacterial.fa.gz > PWD/outdata/PHACA/Phalacrocorax_carbo.scaf.noBacterial.fa && echo gzip PHACA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PHACA/Phalacrocorax_carbo.scaf.noBacterial.fa && echo rptmd PHACA was OK 
 ln -s PWD/outdata/PHACA/result/consensi.fa.classified PWD/outdata/PHACA/final.library && echo ln -s PHACA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PHACA/final.library PWD/outdata/PHACA/Phalacrocorax_carbo.scaf.noBacterial.fa && echo denovo annotation PHACA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PHACA/Phalacrocorax_carbo.denovo.RepeatMasker.out > PWD/outdata/PHACA/Phalacrocorax_carbo.denovo.RepeatMasker.out.filter && echo filter denovo .out PHACA was OK 
 mv PWD/outdata/PHACA/Phalacrocorax_carbo.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PHACA/Phalacrocorax_carbo.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PHACA/Phalacrocorax_carbo.scaf.noBacterial.fa && echo repbase annotation PHACA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PHACA/Phalacrocorax_carbo.known.RepeatMasker.out > PWD/outdata/PHACA/Phalacrocorax_carbo.known.RepeatMasker.out.filter && echo filter repbase .out PHACA was OK 
 mv PWD/outdata/PHACA/Phalacrocorax_carbo.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PHACA/Phalacrocorax_carbo.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PHACA 
