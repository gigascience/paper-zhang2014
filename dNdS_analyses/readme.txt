The input file should be the CDS alignment, with the suffix ".cds" (e.g. 12345.cds). Following are 3 examples:

[1] Estimate the overall dNdS ratio (one-ratio branch model):
	sh paml.m0.sh 12345

[2] Estimate the dNdS ratio for each of 3 major avian clades (three-ratio branch model):
	sh paml.m2.sh 12345

[3] Execute both the one ratio model and two ratio model:
	sh work.sh 12345


To estimate the overall dNdS ratios for mammal orthologous genes, uses the script "paml.m0.mammal.sh" instead of "paml.m0.sh".

The version of programs:
treebest	1.9.2
codeml	4.4
