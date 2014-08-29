maf=$1

mkdir -p $maf.split.mammal/$maf
./bin/msa_split $maf --in-format MAF  --windows 1000000,0 --out-root $maf.split.mammal/$maf/$maf --out-format SS --min-informative 1000 --between-blocks 5000

