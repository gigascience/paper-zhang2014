#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Haliaeetus_albicilla.scaf.noBacterial.fa.gz > PWD/outdata/HALAL/Haliaeetus_albicilla.scaf.noBacterial.fa && echo gzip HALAL was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/HALAL/Haliaeetus_albicilla.scaf.noBacterial.fa && echo rptmd HALAL was OK 
 ln -s PWD/outdata/HALAL/result/consensi.fa.classified PWD/outdata/HALAL/final.library && echo ln -s HALAL was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/HALAL/final.library PWD/outdata/HALAL/Haliaeetus_albicilla.scaf.noBacterial.fa && echo denovo annotation HALAL was OK 
 perl PWD/bin/out_format.pl PWD/outdata/HALAL/Haliaeetus_albicilla.denovo.RepeatMasker.out > PWD/outdata/HALAL/Haliaeetus_albicilla.denovo.RepeatMasker.out.filter && echo filter denovo .out HALAL was OK 
 mv PWD/outdata/HALAL/Haliaeetus_albicilla.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/HALAL/Haliaeetus_albicilla.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/HALAL/Haliaeetus_albicilla.scaf.noBacterial.fa && echo repbase annotation HALAL was OK 
  perl PWD/bin/out_format.pl PWD/outdata/HALAL/Haliaeetus_albicilla.known.RepeatMasker.out > PWD/outdata/HALAL/Haliaeetus_albicilla.known.RepeatMasker.out.filter && echo filter repbase .out HALAL was OK 
 mv PWD/outdata/HALAL/Haliaeetus_albicilla.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/HALAL/Haliaeetus_albicilla.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  HALAL 
