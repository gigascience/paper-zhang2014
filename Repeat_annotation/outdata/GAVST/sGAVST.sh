#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Gavia_stellata.scaf.noBacterial.fa.gz > PWD/outdata/GAVST/Gavia_stellata.scaf.noBacterial.fa && echo gzip GAVST was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/GAVST/Gavia_stellata.scaf.noBacterial.fa && echo rptmd GAVST was OK 
 ln -s PWD/outdata/GAVST/result/consensi.fa.classified PWD/outdata/GAVST/final.library && echo ln -s GAVST was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/GAVST/final.library PWD/outdata/GAVST/Gavia_stellata.scaf.noBacterial.fa && echo denovo annotation GAVST was OK 
 perl PWD/bin/out_format.pl PWD/outdata/GAVST/Gavia_stellata.denovo.RepeatMasker.out > PWD/outdata/GAVST/Gavia_stellata.denovo.RepeatMasker.out.filter && echo filter denovo .out GAVST was OK 
 mv PWD/outdata/GAVST/Gavia_stellata.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/GAVST/Gavia_stellata.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/GAVST/Gavia_stellata.scaf.noBacterial.fa && echo repbase annotation GAVST was OK 
  perl PWD/bin/out_format.pl PWD/outdata/GAVST/Gavia_stellata.known.RepeatMasker.out > PWD/outdata/GAVST/Gavia_stellata.known.RepeatMasker.out.filter && echo filter repbase .out GAVST was OK 
 mv PWD/outdata/GAVST/Gavia_stellata.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/GAVST/Gavia_stellata.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  GAVST 
