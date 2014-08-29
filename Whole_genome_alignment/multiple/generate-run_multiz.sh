chr=$1

mkdir $chr
python ./bin/run_multiz.py --pair_align pairwise_alignment_$chr.list --tree "((STRCA TINMA) ((((((((((((((ACACH ((CORBR (GEOFO TAEGU)) MANVI)) (MELUN NESNO)) FALPE) ((APAVI (BUCRH (MERNU PICPU))) LEPDI)) (CARCR COLST)) ((CATAU HALAL) TYTAL)) (PHORU PODCR)) (((((APTFO PYGAD) FULGL) (((EGRGA PELCR) NIPNI) PHACA)) GAVST) (EURHE PHALE))) BALRE) CAPCA) ((CHLUN TAUER) (MESUN PTEGU))) (((CALAN CHAPE) CUCCA) (CHAVO OPHHO))) COLLI) (ANAPL (GALGA MELGA))))" --out ./$chr
cd chrW

sed -i -e 's/maf_project/..\/bin\/maf_project/' -e 's/multiz/..\/bin\/multiz/' run_multiz.sh 

sh run_multiz.sh

