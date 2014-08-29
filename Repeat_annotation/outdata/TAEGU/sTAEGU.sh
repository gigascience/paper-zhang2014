#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Taeniopygia_guttata.taeGut3.2.4.60.dna.toplevel.fa.gz > PWD/outdata/TAEGU/Taeniopygia_guttata.taeGut3.2.4.60.dna.toplevel.fa && echo gzip TAEGU was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/TAEGU/Taeniopygia_guttata.taeGut3.2.4.60.dna.toplevel.fa && echo rptmd TAEGU was OK 
 ln -s PWD/outdata/TAEGU/result/consensi.fa.classified PWD/outdata/TAEGU/final.library && echo ln -s TAEGU was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/TAEGU/final.library PWD/outdata/TAEGU/Taeniopygia_guttata.taeGut3.2.4.60.dna.toplevel.fa && echo denovo annotation TAEGU was OK 
 perl PWD/bin/out_format.pl PWD/outdata/TAEGU/Taeniopygia_guttata.denovo.RepeatMasker.out > PWD/outdata/TAEGU/Taeniopygia_guttata.denovo.RepeatMasker.out.filter && echo filter denovo .out TAEGU was OK 
 mv PWD/outdata/TAEGU/Taeniopygia_guttata.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/TAEGU/Taeniopygia_guttata.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/TAEGU/Taeniopygia_guttata.taeGut3.2.4.60.dna.toplevel.fa && echo repbase annotation TAEGU was OK 
  perl PWD/bin/out_format.pl PWD/outdata/TAEGU/Taeniopygia_guttata.known.RepeatMasker.out > PWD/outdata/TAEGU/Taeniopygia_guttata.known.RepeatMasker.out.filter && echo filter repbase .out TAEGU was OK 
 mv PWD/outdata/TAEGU/Taeniopygia_guttata.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/TAEGU/Taeniopygia_guttata.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  TAEGU 
