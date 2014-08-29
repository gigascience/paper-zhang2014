#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Phoenicopterus_ruber.scaf.noBacterial.fa.gz > PWD/outdata/PHORU/Phoenicopterus_ruber.scaf.noBacterial.fa && echo gzip PHORU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PHORU/Phoenicopterus_ruber.scaf.noBacterial.fa && echo rptmd PHORU was OK 
 ln -s PWD/outdata/PHORU/result/consensi.fa.classified PWD/outdata/PHORU/final.library && echo ln -s PHORU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PHORU/final.library PWD/outdata/PHORU/Phoenicopterus_ruber.scaf.noBacterial.fa && echo denovo annotation PHORU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PHORU/Phoenicopterus_ruber.denovo.RepeatMasker.out > PWD/outdata/PHORU/Phoenicopterus_ruber.denovo.RepeatMasker.out.filter && echo filter denovo .out PHORU was OK 
 mv PWD/outdata/PHORU/Phoenicopterus_ruber.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PHORU/Phoenicopterus_ruber.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PHORU/Phoenicopterus_ruber.scaf.noBacterial.fa && echo repbase annotation PHORU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PHORU/Phoenicopterus_ruber.known.RepeatMasker.out > PWD/outdata/PHORU/Phoenicopterus_ruber.known.RepeatMasker.out.filter && echo filter repbase .out PHORU was OK 
 mv PWD/outdata/PHORU/Phoenicopterus_ruber.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PHORU/Phoenicopterus_ruber.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PHORU 
