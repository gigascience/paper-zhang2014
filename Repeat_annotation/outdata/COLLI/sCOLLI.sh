#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Columba_livia.scaf.fa.gz > PWD/outdata/COLLI/Columba_livia.scaf.fa && echo gzip COLLI was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/COLLI/Columba_livia.scaf.fa && echo rptmd COLLI was OK 
 ln -s PWD/outdata/COLLI/result/consensi.fa.classified PWD/outdata/COLLI/final.library && echo ln -s COLLI was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/COLLI/final.library PWD/outdata/COLLI/Columba_livia.scaf.fa && echo denovo annotation COLLI was OK 
 perl PWD/bin/out_format.pl PWD/outdata/COLLI/Columba_livia.denovo.RepeatMasker.out > PWD/outdata/COLLI/Columba_livia.denovo.RepeatMasker.out.filter && echo filter denovo .out COLLI was OK 
 mv PWD/outdata/COLLI/Columba_livia.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/COLLI/Columba_livia.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/COLLI/Columba_livia.scaf.fa && echo repbase annotation COLLI was OK 
  perl PWD/bin/out_format.pl PWD/outdata/COLLI/Columba_livia.known.RepeatMasker.out > PWD/outdata/COLLI/Columba_livia.known.RepeatMasker.out.filter && echo filter repbase .out COLLI was OK 
 mv PWD/outdata/COLLI/Columba_livia.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/COLLI/Columba_livia.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  COLLI 
