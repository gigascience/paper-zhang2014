#!/bin/sh
#a small pipeline of PILER-DF
if [ $# -lt 1 ]
then 
	echo " Usage:$0 <genome.fa><cut> "
	exit 1
fi

genome=`basename $1`
cut=$2
hit=$genome.hit.gff
trs=$genome.hit.trs.gff
fams=$genome\_fams
cons=$genome\_cons
aligned_fams=$genome\_aligned_fams
library=$genome.piler_library.fa
log=$genome.piler.log
while [ -e $log ]
do
	rm -r $log
done
#local align
fastaDeal -cutf $cut $1
perl /ifs2/BC_GAG/Bin/Annotation/software/piler-sz/pipeline.pl  $1.cut/
qsub-sge.pl -maxjob $cut -reqsub find_pals.sh

echo local-align-finished;
#trs
/ifs2/BC_GAG/Bin/Annotation/software/piler-sz/piler/piler -trs $hit -out $trs 1>>$log 2>&1
echo trs-finished;
while [ -d $fams ] 
do
 	rm -r $fams
done
until [ -d $fams ]
do
	mkdir $fams
done

#get seq
/ifs2/BC_GAG/Bin/Annotation/software/piler-sz/piler/piler -trs2fasta $trs -seq $1 -path $fams 1>>$log 2>&1
echo piler-finished;
while [ -d $aligned_fams ]
do
	rm -r $aligned_fams
done
until [ -d $aligned_fams ]
do
	mkdir $aligned_fams
done
cd $fams
#muscle
for fam in *
do
	muscle -in $fam -out ../$aligned_fams/$fam -maxiters 1 -diags1 1>>$log 2>&1
done
echo muscle-finished;
cd ..
while [ -d $cons ]
do
	rm -r $cons
done
until [ -d $cons ]
do
	mkdir $cons
done
cd $aligned_fams
#get cons seq 
for fam in *
do
	/ifs2/BC_GAG/Bin/Annotation/software/piler-sz/piler/piler   -cons $fam -out ../$cons/$fam -label $fam 1>>$log 2>&1	
done
cd ../$cons
cat * > ../$library
echo cons-finished;
echo all-finished;

