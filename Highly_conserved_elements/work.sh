### generate the script to obtain the 4-fold generate site
mkdir 4d_sites; cat maf-file.list | while read line; do echo "./bin/msa_view $line --in-format MAF --4d --features Gallus_gallus.gff > 4d_sites/$line.codon.ss" ;done >  get_4d_site.sh
### run she script to obtain the 4-fold generate site
sh get_4d_site.sh


### generate and execute the script to transform the format of 4-fold generate site form SS to FASTA
cat maf-file.list | while read line; do echo "./bin/msa_view 4d_sites/$line.codon.ss  --in-format SS --out-format FASTA  --tuple-size 1 > 4d_sites/$line.sites.fa";done > ss2fa.sh
sh ss2fa.sh

### generate and execute the script to estimate the nonconserve model for each chromosome
cat maf-file.list | while read line; do echo "./bin/phyloFit  --tree \"((((((((((((((PICPU,MERNU),BUCRH),APAVI),LEPDI),(COLST,TYTAL)),(CATAU,(HALAL,HALLE))),(CARCR,(FALPE,((MELUN,NESNO),(ACACH,(MANVI,(CORBR,(TAEGU,GEOFO)))))))),((PHALE,EURHE),(GAVST,(((APTFO,PYGAD),FULGL),(PHACA,(NIPNI,(EGRGA,PELCR))))))),(CHAVO,BALRE)),OPHHO),((TAUER,CHLUN),(CUCCA,(CAPCA,(CALAN,CHAPE))))),((PHORU,PODCR),(COLLI,(PTEGU,MESUN)))),(ANAPL,(MELGA,GALGA))),(TINMA,STRCA))\" --msa-format FASTA  --out-root  4d_sites/$line.nonconserved-4d.mod 4d_sites/$line.sites.fa" ;done > estimate_parameter.sh
sh estimate_parameter.sh

### obtain the average nonconserve model
ls 4d_sites/*.mod  > all_mod.list
./bin/phyloBoot --read-mods 'all_mod.list'  --output-average ave.noncons.mod 

### split the MSA files into smaller pieces
#sh split.sh $maf
cat maf-file.list | while read line; do echo "sh split.sh $line" ;done > run_split.sh
sh run_split.sh

### generate and execute the script to estimate conserve model
cat maf-file.list | while read line; do echo "cd $line.split/$line; ls *.ss | while read ss; do ../../bin/phastCons --estimate-rho \$ss --no-post-probs \$ss ../../ave.noncons.mod; done ;cd - ";done > get_conserved_model.sh
sh get_conserved_model.sh

### obtain the average conserve model
ls *split/*/*.ss.cons.mod > cons.txt
./bin/phyloBoot --read-mods '*cons.txt' --output-average ave.cons.mod

### generate and execute the script to run phastCons to predict HCEs
mkdir ELEMENTS; mkdir SCORES; cat maf-file.list | while read line; do sh phastCons.sh $line; done
#sh phastCons.sh $maf
sh run_phastCons.sh
