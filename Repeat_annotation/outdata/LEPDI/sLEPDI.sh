#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Leptosomus_discolor.scaf.noBacterial.fa.gz > PWD/outdata/LEPDI/Leptosomus_discolor.scaf.noBacterial.fa && echo gzip LEPDI was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/LEPDI/Leptosomus_discolor.scaf.noBacterial.fa && echo rptmd LEPDI was OK 
 ln -s PWD/outdata/LEPDI/result/consensi.fa.classified PWD/outdata/LEPDI/final.library && echo ln -s LEPDI was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/LEPDI/final.library PWD/outdata/LEPDI/Leptosomus_discolor.scaf.noBacterial.fa && echo denovo annotation LEPDI was OK 
 perl PWD/bin/out_format.pl PWD/outdata/LEPDI/Leptosomus_discolor.denovo.RepeatMasker.out > PWD/outdata/LEPDI/Leptosomus_discolor.denovo.RepeatMasker.out.filter && echo filter denovo .out LEPDI was OK 
 mv PWD/outdata/LEPDI/Leptosomus_discolor.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/LEPDI/Leptosomus_discolor.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/LEPDI/Leptosomus_discolor.scaf.noBacterial.fa && echo repbase annotation LEPDI was OK 
  perl PWD/bin/out_format.pl PWD/outdata/LEPDI/Leptosomus_discolor.known.RepeatMasker.out > PWD/outdata/LEPDI/Leptosomus_discolor.known.RepeatMasker.out.filter && echo filter repbase .out LEPDI was OK 
 mv PWD/outdata/LEPDI/Leptosomus_discolor.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/LEPDI/Leptosomus_discolor.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  LEPDI 
