cds=$1

perl ./bin/phylip.pl $cds.cds $cds.phylip $cds.cds.spe

perl ./bin/TreeBest.pl species.tree $cds.cds.spe $cds.cds.spe.tree.new

perl ./bin/CodeML.pl -seqfile $cds.phylip -treefile $cds.cds.spe.tree.new -o $cds

