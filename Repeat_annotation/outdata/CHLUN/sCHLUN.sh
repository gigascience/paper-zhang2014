#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Chlamydotis_undulata.scaf.noBacterial.fa.gz > PWD/outdata/CHLUN/Chlamydotis_undulata.scaf.noBacterial.fa && echo gzip CHLUN was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/CHLUN/Chlamydotis_undulata.scaf.noBacterial.fa && echo rptmd CHLUN was OK 
 ln -s PWD/outdata/CHLUN/result/consensi.fa.classified PWD/outdata/CHLUN/final.library && echo ln -s CHLUN was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/CHLUN/final.library PWD/outdata/CHLUN/Chlamydotis_undulata.scaf.noBacterial.fa && echo denovo annotation CHLUN was OK 
 perl PWD/bin/out_format.pl PWD/outdata/CHLUN/Chlamydotis_undulata.denovo.RepeatMasker.out > PWD/outdata/CHLUN/Chlamydotis_undulata.denovo.RepeatMasker.out.filter && echo filter denovo .out CHLUN was OK 
 mv PWD/outdata/CHLUN/Chlamydotis_undulata.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/CHLUN/Chlamydotis_undulata.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/CHLUN/Chlamydotis_undulata.scaf.noBacterial.fa && echo repbase annotation CHLUN was OK 
  perl PWD/bin/out_format.pl PWD/outdata/CHLUN/Chlamydotis_undulata.known.RepeatMasker.out > PWD/outdata/CHLUN/Chlamydotis_undulata.known.RepeatMasker.out.filter && echo filter repbase .out CHLUN was OK 
 mv PWD/outdata/CHLUN/Chlamydotis_undulata.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/CHLUN/Chlamydotis_undulata.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  CHLUN 
