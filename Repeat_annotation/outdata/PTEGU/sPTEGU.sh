#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Pterocles_guturalis.scaf.noBacterial.fa.gz > PWD/outdata/PTEGU/Pterocles_guturalis.scaf.noBacterial.fa && echo gzip PTEGU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/PTEGU/Pterocles_guturalis.scaf.noBacterial.fa && echo rptmd PTEGU was OK 
 ln -s PWD/outdata/PTEGU/result/consensi.fa.classified PWD/outdata/PTEGU/final.library && echo ln -s PTEGU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/PTEGU/final.library PWD/outdata/PTEGU/Pterocles_guturalis.scaf.noBacterial.fa && echo denovo annotation PTEGU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/PTEGU/Pterocles_guturalis.denovo.RepeatMasker.out > PWD/outdata/PTEGU/Pterocles_guturalis.denovo.RepeatMasker.out.filter && echo filter denovo .out PTEGU was OK 
 mv PWD/outdata/PTEGU/Pterocles_guturalis.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/PTEGU/Pterocles_guturalis.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/PTEGU/Pterocles_guturalis.scaf.noBacterial.fa && echo repbase annotation PTEGU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/PTEGU/Pterocles_guturalis.known.RepeatMasker.out > PWD/outdata/PTEGU/Pterocles_guturalis.known.RepeatMasker.out.filter && echo filter repbase .out PTEGU was OK 
 mv PWD/outdata/PTEGU/Pterocles_guturalis.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/PTEGU/Pterocles_guturalis.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  PTEGU 
