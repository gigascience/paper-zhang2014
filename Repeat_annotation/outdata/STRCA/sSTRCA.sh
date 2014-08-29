#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Struthio_camelus.scaf.noBacterial.fa.gz > PWD/outdata/STRCA/Struthio_camelus.scaf.noBacterial.fa && echo gzip STRCA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/STRCA/Struthio_camelus.scaf.noBacterial.fa && echo rptmd STRCA was OK 
 ln -s PWD/outdata/STRCA/result/consensi.fa.classified PWD/outdata/STRCA/final.library && echo ln -s STRCA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/STRCA/final.library PWD/outdata/STRCA/Struthio_camelus.scaf.noBacterial.fa && echo denovo annotation STRCA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/STRCA/Struthio_camelus.denovo.RepeatMasker.out > PWD/outdata/STRCA/Struthio_camelus.denovo.RepeatMasker.out.filter && echo filter denovo .out STRCA was OK 
 mv PWD/outdata/STRCA/Struthio_camelus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/STRCA/Struthio_camelus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/STRCA/Struthio_camelus.scaf.noBacterial.fa && echo repbase annotation STRCA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/STRCA/Struthio_camelus.known.RepeatMasker.out > PWD/outdata/STRCA/Struthio_camelus.known.RepeatMasker.out.filter && echo filter repbase .out STRCA was OK 
 mv PWD/outdata/STRCA/Struthio_camelus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/STRCA/Struthio_camelus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  STRCA 
