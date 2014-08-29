#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Buceros_rhinoceros_silvestris.scaf.noBacterial.fa.gz > PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.scaf.noBacterial.fa && echo gzip BUCRH was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.scaf.noBacterial.fa && echo rptmd BUCRH was OK 
 ln -s PWD/outdata/BUCRH/result/consensi.fa.classified PWD/outdata/BUCRH/final.library && echo ln -s BUCRH was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/BUCRH/final.library PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.scaf.noBacterial.fa && echo denovo annotation BUCRH was OK 
 perl PWD/bin/out_format.pl PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.denovo.RepeatMasker.out > PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.denovo.RepeatMasker.out.filter && echo filter denovo .out BUCRH was OK 
 mv PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.scaf.noBacterial.fa && echo repbase annotation BUCRH was OK 
  perl PWD/bin/out_format.pl PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.known.RepeatMasker.out > PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.known.RepeatMasker.out.filter && echo filter repbase .out BUCRH was OK 
 mv PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/BUCRH/Buceros_rhinoceros_silvestris.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  BUCRH 
