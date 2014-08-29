#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Geospiza_fortis.scaf.noBacterial.fa.gz > PWD/outdata/GEOFO/Geospiza_fortis.scaf.noBacterial.fa && echo gzip GEOFO was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/GEOFO/Geospiza_fortis.scaf.noBacterial.fa && echo rptmd GEOFO was OK 
 ln -s PWD/outdata/GEOFO/result/consensi.fa.classified PWD/outdata/GEOFO/final.library && echo ln -s GEOFO was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/GEOFO/final.library PWD/outdata/GEOFO/Geospiza_fortis.scaf.noBacterial.fa && echo denovo annotation GEOFO was OK 
 perl PWD/bin/out_format.pl PWD/outdata/GEOFO/Geospiza_fortis.denovo.RepeatMasker.out > PWD/outdata/GEOFO/Geospiza_fortis.denovo.RepeatMasker.out.filter && echo filter denovo .out GEOFO was OK 
 mv PWD/outdata/GEOFO/Geospiza_fortis.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/GEOFO/Geospiza_fortis.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/GEOFO/Geospiza_fortis.scaf.noBacterial.fa && echo repbase annotation GEOFO was OK 
  perl PWD/bin/out_format.pl PWD/outdata/GEOFO/Geospiza_fortis.known.RepeatMasker.out > PWD/outdata/GEOFO/Geospiza_fortis.known.RepeatMasker.out.filter && echo filter repbase .out GEOFO was OK 
 mv PWD/outdata/GEOFO/Geospiza_fortis.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/GEOFO/Geospiza_fortis.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  GEOFO 
