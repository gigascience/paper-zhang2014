#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Anas_platyrhynchos_domestica.scaf.fa.gz > PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.scaf.fa && echo gzip ANAPL was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.scaf.fa && echo rptmd ANAPL was OK 
 ln -s PWD/outdata/ANAPL/result/consensi.fa.classified PWD/outdata/ANAPL/final.library && echo ln -s ANAPL was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/ANAPL/final.library PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.scaf.fa && echo denovo annotation ANAPL was OK 
 perl PWD/bin/out_format.pl PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.denovo.RepeatMasker.out > PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.denovo.RepeatMasker.out.filter && echo filter denovo .out ANAPL was OK 
 mv PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.scaf.fa && echo repbase annotation ANAPL was OK 
  perl PWD/bin/out_format.pl PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.known.RepeatMasker.out > PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.known.RepeatMasker.out.filter && echo filter repbase .out ANAPL was OK 
 mv PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/ANAPL/Anas_platyrhynchos_domestica.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  ANAPL 
