cds=$1

perl ./bin/phylip.pl $cds.cds $cds.phylip $cds.cds.spe

perl ./bin/TreeBest.pl species.tree $cds.cds.spe $cds.cds.spe.tree.new

sed -i -e 's/ANAPL/ANAPL #1/' -e 's/GALGA/GALGA #1/' -e 's/MELGA/MELGA #1/' -e 's/(ANAPL #1,GALGA #1)/(ANAPL #1,GALGA #1) #1/' -e 's/(ANAPL #1,MELGA #1)/(ANAPL #1,MELGA #1) #1/' -e 's/(MELGA #1,GALGA #1)/(MELGA #1,GALGA #1) #1/' -e 's/(ANAPL #1,(MELGA #1,GALGA #1) #1)/(ANAPL #1,(MELGA #1,GALGA #1) #1) #1/' -e 's/TINMA/TINMA #2/' -e 's/STRCA/STRCA #2/' -e 's/(TINMA #2,STRCA #2)/(TINMA #2,STRCA #2) #2/' $cds.cds.spe.tree.new

perl ./bin/CodeML.pl -seqfile $cds.phylip -treefile $cds.cds.spe.tree.new -o $cds -model 2

