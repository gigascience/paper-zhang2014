
### split the mammalian MSA files
cat maf-file.mammal.list | while read line; do sh split.mammal.sh $line; done


### generate and execute the script to predict mammalian HCEs
mkdir ELEMENTS_mammal; mkdir SCORES_mammal; cat maf-file.mammal.list  | while read line; do sh phastCons.mammal.sh $maf;done
sh run_phastCons_mammal.sh
