#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Pelecanus_crispus.scaf.noBacterial.fa.gz > PWD/outdata/PELCR/Pelecanus_crispus.scaf.noBacterial.fa && echo gzip PELCR was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PELCR/Pelecanus_crispus.scaf.noBacterial.fa && echo rptmd PELCR was OK 
 ln -s PWD/outdata/PELCR/result/consensi.fa.classified PWD/outdata/PELCR/final.library && echo ln -s PELCR was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PELCR/final.library PWD/outdata/PELCR/Pelecanus_crispus.scaf.noBacterial.fa && echo denovo annotation PELCR was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PELCR/Pelecanus_crispus.denovo.RepeatMasker.out > PWD/outdata/PELCR/Pelecanus_crispus.denovo.RepeatMasker.out.filter && echo filter denovo .out PELCR was OK 
 mv PWD/outdata/PELCR/Pelecanus_crispus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PELCR/Pelecanus_crispus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PELCR/Pelecanus_crispus.scaf.noBacterial.fa && echo repbase annotation PELCR was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PELCR/Pelecanus_crispus.known.RepeatMasker.out > PWD/outdata/PELCR/Pelecanus_crispus.known.RepeatMasker.out.filter && echo filter repbase .out PELCR was OK 
 mv PWD/outdata/PELCR/Pelecanus_crispus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PELCR/Pelecanus_crispus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PELCR 
