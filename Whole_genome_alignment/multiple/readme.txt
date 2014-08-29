Whole genome alignments used the chicken genome (galGal3) as the reference genome. 

The input data are pairwise alignments between chicken and other birds. We
generated the multiple sequence alignment for each chromosome separately. For
example, to get the multiple species alignment for chromosome W, the input data
are the pairwise alignments between chicken chromosome W and each bird genome.

The information of pairwise alignments should be prepared in the file
"pairwise_alignment_X.list", where X need to be replaced by a chromosome name,
such as "chrW". In the file list, the second row indicates the abbreviations
for each bird, and the third row indicates the paths for the pairwise alignment
files.

The command to run the whole genome alignments should be:
"sh generate-run_multiz.sh X"
"X" should be replaced by a chromosome name corresponding to the "pairwise_alignment_X.list" mentioned above. 

We used programs in 'multiz-tba' package (release: 2009-Jan-21)
roast	v3
maf_project	v12
multiz	v11.2
