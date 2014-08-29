#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Meleagris_gallopavo.UMD2.61.dna.toplevel.fa.gz > PWD/outdata/MELGA/Meleagris_gallopavo.UMD2.61.dna.toplevel.fa && echo gzip MELGA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/MELGA/Meleagris_gallopavo.UMD2.61.dna.toplevel.fa && echo rptmd MELGA was OK 
 ln -s PWD/outdata/MELGA/result/consensi.fa.classified PWD/outdata/MELGA/final.library && echo ln -s MELGA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/MELGA/final.library PWD/outdata/MELGA/Meleagris_gallopavo.UMD2.61.dna.toplevel.fa && echo denovo annotation MELGA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/MELGA/Meleagris_gallopavo.denovo.RepeatMasker.out > PWD/outdata/MELGA/Meleagris_gallopavo.denovo.RepeatMasker.out.filter && echo filter denovo .out MELGA was OK 
 mv PWD/outdata/MELGA/Meleagris_gallopavo.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/MELGA/Meleagris_gallopavo.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/MELGA/Meleagris_gallopavo.UMD2.61.dna.toplevel.fa && echo repbase annotation MELGA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/MELGA/Meleagris_gallopavo.known.RepeatMasker.out > PWD/outdata/MELGA/Meleagris_gallopavo.known.RepeatMasker.out.filter && echo filter repbase .out MELGA was OK 
 mv PWD/outdata/MELGA/Meleagris_gallopavo.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/MELGA/Meleagris_gallopavo.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  MELGA 
