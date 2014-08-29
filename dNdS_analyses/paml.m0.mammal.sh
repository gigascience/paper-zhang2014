cds=$1

perl ./bin/phylip.pl $cds.cds $cds.mammal.phylip $cds.cds.mammal.spe

sed -i 's/.*_//g' $cds.cds.mammal.spe
sed -i 's/.*_//g' $cds.mammal.phylip

perl ./bin/TreeBest.pl species.tree.mammal.nwk $cds.cds.mammal.spe $cds.cds.mammal.spe.tree.new

perl ./bin/CodeML.pl -seqfile $cds.mammal.phylip -treefile $cds.cds.mammal.spe.tree.new -o $cds.mammal

