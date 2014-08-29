#!/bin/sh
 gzip -dc /Scaffold/Data/Path/Melopsittacus_undulatus.ap_v6_sli_asm.scf.fasta.gz > PWD/outdata/MELUN/Melopsittacus_undulatus.ap_v6_sli_asm.scf.fasta && echo gzip MELUN was OK
 perl PWD/bin/denovo_repeat_find.pl -RepeatModeler PWD/outdata/MELUN/Melopsittacus_undulatus.ap_v6_sli_asm.scf.fasta && echo rptmd MELUN was OK 
 ln -s PWD/outdata/MELUN/result/consensi.fa.classified PWD/outdata/MELUN/final.library && echo ln -s MELUN was OK 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g -lib PWD/outdata/MELUN/final.library PWD/outdata/MELUN/Melopsittacus_undulatus.ap_v6_sli_asm.scf.fasta && echo denovo annotation MELUN was OK 
 perl PWD/bin/out_format.pl PWD/outdata/MELUN/Melopsittacus_undulatus.denovo.RepeatMasker.out > PWD/outdata/MELUN/Melopsittacus_undulatus.denovo.RepeatMasker.out.filter && echo filter denovo .out MELUN was OK 
 mv PWD/outdata/MELUN/Melopsittacus_undulatus.denovo.RepeatMasker.out.filter PWD/denovo/out && mv PWD/outdata/MELUN/Melopsittacus_undulatus.denovo.RepeatMasker.gff PWD/denovo/gff && echo backup denovo 
 perl PWD/bin/find_repeat.pl -repeatmasker -sensitive -cpu 50 -cutf 50 -run qsub -resource vf=3g PWD/outdata/MELUN/Melopsittacus_undulatus.ap_v6_sli_asm.scf.fasta && echo repbase annotation MELUN was OK 
  perl PWD/bin/out_format.pl PWD/outdata/MELUN/Melopsittacus_undulatus.known.RepeatMasker.out > PWD/outdata/MELUN/Melopsittacus_undulatus.known.RepeatMasker.out.filter && echo filter repbase .out MELUN was OK 
 mv PWD/outdata/MELUN/Melopsittacus_undulatus.known.RepeatMasker.out.filter PWD/repbase/out && mv PWD/outdata/MELUN/Melopsittacus_undulatus.known.RepeatMasker.gff PWD/repbase/gff && echo backup repbase  MELUN 
