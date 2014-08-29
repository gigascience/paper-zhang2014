#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Pygoscelis_adeliae.scaf.fa.gz > PWD/outdata/PYGAD/Pygoscelis_adeliae.scaf.fa && echo gzip PYGAD was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PYGAD/Pygoscelis_adeliae.scaf.fa && echo rptmd PYGAD was OK 
 ln -s PWD/outdata/PYGAD/result/consensi.fa.classified PWD/outdata/PYGAD/final.library && echo ln -s PYGAD was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PYGAD/final.library PWD/outdata/PYGAD/Pygoscelis_adeliae.scaf.fa && echo denovo annotation PYGAD was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PYGAD/Pygoscelis_adeliae.denovo.RepeatMasker.out > PWD/outdata/PYGAD/Pygoscelis_adeliae.denovo.RepeatMasker.out.filter && echo filter denovo .out PYGAD was OK 
 mv PWD/outdata/PYGAD/Pygoscelis_adeliae.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PYGAD/Pygoscelis_adeliae.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PYGAD/Pygoscelis_adeliae.scaf.fa && echo repbase annotation PYGAD was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PYGAD/Pygoscelis_adeliae.known.RepeatMasker.out > PWD/outdata/PYGAD/Pygoscelis_adeliae.known.RepeatMasker.out.filter && echo filter repbase .out PYGAD was OK 
 mv PWD/outdata/PYGAD/Pygoscelis_adeliae.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PYGAD/Pygoscelis_adeliae.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PYGAD 
