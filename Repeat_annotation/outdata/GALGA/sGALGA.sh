#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Gallus_gallus.WASHUC2.60.dna.toplevel.fa.gz > PWD/outdata/GALGA/Gallus_gallus.WASHUC2.60.dna.toplevel.fa && echo gzip GALGA was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/GALGA/Gallus_gallus.WASHUC2.60.dna.toplevel.fa && echo rptmd GALGA was OK 
 ln -s PWD/outdata/GALGA/result/consensi.fa.classified PWD/outdata/GALGA/final.library && echo ln -s GALGA was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/GALGA/final.library PWD/outdata/GALGA/Gallus_gallus.WASHUC2.60.dna.toplevel.fa && echo denovo annotation GALGA was OK 
 perl PWD/bin/out_format.pl PWD/outdata/GALGA/Gallus_gallus.denovo.RepeatMasker.out > PWD/outdata/GALGA/Gallus_gallus.denovo.RepeatMasker.out.filter && echo filter denovo .out GALGA was OK 
 mv PWD/outdata/GALGA/Gallus_gallus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/GALGA/Gallus_gallus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/GALGA/Gallus_gallus.WASHUC2.60.dna.toplevel.fa && echo repbase annotation GALGA was OK 
  perl PWD/bin/out_format.pl PWD/outdata/GALGA/Gallus_gallus.known.RepeatMasker.out > PWD/outdata/GALGA/Gallus_gallus.known.RepeatMasker.out.filter && echo filter repbase .out GALGA was OK 
 mv PWD/outdata/GALGA/Gallus_gallus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/GALGA/Gallus_gallus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  GALGA 
