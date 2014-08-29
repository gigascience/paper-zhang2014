maf=$1

ls $maf.split/$maf/ | while read line; do echo "./bin/phastCons --most-conserved ELEMENTS/$line.bed --score $maf.split/$maf/$line ave.cons.mod,ave.noncons.mod > SCORES/$line.wig ";done  >> run_phastCons.sh

