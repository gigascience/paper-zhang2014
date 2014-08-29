### the input 'cds' should be the prefix of CDS alignment (e.g. if the alignment file is 12345.cds, the commond should be sh work.mammal.sh 12345)
cds=$1

### estimate the overall dNds ratio (tne ratio model)
sh paml.m0.mammal.sh $cds


