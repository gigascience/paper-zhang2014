#!/bin/sh
perl bin/pipeline_rpt_denovo.pl ave.scaf.list config.txt /Scaffold/Data/Path
perl bin/qsub-sge.pl qsub-sge.pl --lines 1 --resource  vf=3G  -reqsub run.sh &
