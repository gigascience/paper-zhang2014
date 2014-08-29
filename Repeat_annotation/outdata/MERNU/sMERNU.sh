#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Merops_nubicus.scaf.noBacterial.fa.gz > PWD/outdata/MERNU/Merops_nubicus.scaf.noBacterial.fa && echo gzip MERNU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/MERNU/Merops_nubicus.scaf.noBacterial.fa && echo rptmd MERNU was OK 
 ln -s PWD/outdata/MERNU/result/consensi.fa.classified PWD/outdata/MERNU/final.library && echo ln -s MERNU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/MERNU/final.library PWD/outdata/MERNU/Merops_nubicus.scaf.noBacterial.fa && echo denovo annotation MERNU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/MERNU/Merops_nubicus.denovo.RepeatMasker.out > PWD/outdata/MERNU/Merops_nubicus.denovo.RepeatMasker.out.filter && echo filter denovo .out MERNU was OK 
 mv PWD/outdata/MERNU/Merops_nubicus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/MERNU/Merops_nubicus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/MERNU/Merops_nubicus.scaf.noBacterial.fa && echo repbase annotation MERNU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/MERNU/Merops_nubicus.known.RepeatMasker.out > PWD/outdata/MERNU/Merops_nubicus.known.RepeatMasker.out.filter && echo filter repbase .out MERNU was OK 
 mv PWD/outdata/MERNU/Merops_nubicus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/MERNU/Merops_nubicus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  MERNU 
