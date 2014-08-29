#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Ophisthocomus_hoazin.scaf.noBacterial.fa.gz > PWD/outdata/OPHHO/Ophisthocomus_hoazin.scaf.noBacterial.fa && echo gzip OPHHO was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/OPHHO/Ophisthocomus_hoazin.scaf.noBacterial.fa && echo rptmd OPHHO was OK 
 ln -s PWD/outdata/OPHHO/result/consensi.fa.classified PWD/outdata/OPHHO/final.library && echo ln -s OPHHO was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/OPHHO/final.library PWD/outdata/OPHHO/Ophisthocomus_hoazin.scaf.noBacterial.fa && echo denovo annotation OPHHO was OK 
 perl PWD/bin/out_format.pl PWD/outdata/OPHHO/Ophisthocomus_hoazin.denovo.RepeatMasker.out > PWD/outdata/OPHHO/Ophisthocomus_hoazin.denovo.RepeatMasker.out.filter && echo filter denovo .out OPHHO was OK 
 mv PWD/outdata/OPHHO/Ophisthocomus_hoazin.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/OPHHO/Ophisthocomus_hoazin.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/OPHHO/Ophisthocomus_hoazin.scaf.noBacterial.fa && echo repbase annotation OPHHO was OK 
  perl PWD/bin/out_format.pl PWD/outdata/OPHHO/Ophisthocomus_hoazin.known.RepeatMasker.out > PWD/outdata/OPHHO/Ophisthocomus_hoazin.known.RepeatMasker.out.filter && echo filter repbase .out OPHHO was OK 
 mv PWD/outdata/OPHHO/Ophisthocomus_hoazin.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/OPHHO/Ophisthocomus_hoazin.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  OPHHO 
