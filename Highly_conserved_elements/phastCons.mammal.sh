maf=$1

ls $maf.split.mammal/$maf/ | while read line; do echo "./bin/phastCons --most-conserved ELEMENTS_mammal/$line.bed --score $maf.split.mammal/$maf/$line mammal.cons.mod,mammal.noncons.mod > SCORES_mammal/$line.wig ";done  >> run_phastCons_mammal.sh

