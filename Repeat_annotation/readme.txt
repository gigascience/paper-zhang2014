About pipeline :
1, To creat shells and folder
"perl bin/pipeline_rpt_denovo.pl ave.scaf.list config.txt /Scaffold/Data/Path"

2, To submit the shells to SGE to run parallel jobs (NOTE: SGE represents the 
Linux cluster at BGI, not applicable in other places) 
"perl bin/qsub-sge.pl qsub-sge.pl --lines 1 --resource  vf=3G  -reqsub run.sh &"

  Then, the annotaion results would be in 
   "PWD/denovo"  -->  for denovo 
   "PWD/repbase" -->  for Repbase database 

About inputs : 
<ave.scaf.list>        : It is a file containning three columns, of which the 1st is abbreviated name, 2nd is full name and 3rd is the path of assembly file. The assembly files can be downloaded from "http://phybirds.genomics.org.cn/download.jsp".
<config.txt>           : It is a configuration file;
</Scaffold/Data/Path>  : It is a string for the assembly path.

