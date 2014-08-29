#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Mesitornis_unicolor.scaf.noBacterial.fa.gz > PWD/outdata/MESUN/Mesitornis_unicolor.scaf.noBacterial.fa && echo gzip MESUN was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/MESUN/Mesitornis_unicolor.scaf.noBacterial.fa && echo rptmd MESUN was OK 
 ln -s PWD/outdata/MESUN/result/consensi.fa.classified PWD/outdata/MESUN/final.library && echo ln -s MESUN was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/MESUN/final.library PWD/outdata/MESUN/Mesitornis_unicolor.scaf.noBacterial.fa && echo denovo annotation MESUN was OK 
 perl PWD/bin/out_format.pl PWD/outdata/MESUN/Mesitornis_unicolor.denovo.RepeatMasker.out > PWD/outdata/MESUN/Mesitornis_unicolor.denovo.RepeatMasker.out.filter && echo filter denovo .out MESUN was OK 
 mv PWD/outdata/MESUN/Mesitornis_unicolor.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/MESUN/Mesitornis_unicolor.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/MESUN/Mesitornis_unicolor.scaf.noBacterial.fa && echo repbase annotation MESUN was OK 
  perl PWD/bin/out_format.pl PWD/outdata/MESUN/Mesitornis_unicolor.known.RepeatMasker.out > PWD/outdata/MESUN/Mesitornis_unicolor.known.RepeatMasker.out.filter && echo filter repbase .out MESUN was OK 
 mv PWD/outdata/MESUN/Mesitornis_unicolor.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/MESUN/Mesitornis_unicolor.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  MESUN 
