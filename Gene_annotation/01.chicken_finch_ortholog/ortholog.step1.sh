## Convert the alignment format to table format. The alignment file 'galGal3-taeGut1.net.axt' was downloaded from UCSC.
perl ../bin/netAxt2tab.pl galGal3-taeGut1.net.axt  taeGut1.ucsc.masked.fa.len

## Find overlaps between the net.axt result and coding regions (Ensembl release-60).
perl ../bin/findOverlap_2.pl ./galGal3-taeGut1.net.axt.target.tab  GALGA.cds.tab >  ./galGal3-taeGut1.net.axt.target.tab.ovlp
perl ../bin/findOverlap_2.pl  galGal3-taeGut1.net.axt.query.tab TAEGU.cds.tab  >  galGal3-taeGut1.net.axt.query.tab.ovlp

## Find orthologs
perl ../bin/ortholog_netAxt.pl GALGA.cds.tab TAEGU.cds.tab  galGal3-taeGut1.net.axt.query.tab.ovlp galGal3-taeGut1.net.axt.target.tab.ovlp > GALGA_TAEGU.axt.ortholog

## Filtering
perl ../bin/ortholog_netAxt_coordinateCheck.pl galGal3-taeGut1.net.axt GALGA_TAEGU.axt.ortholog galGal3-taeGut1.net.axt.target.tab.ovlp galGal3-taeGut1.net.axt.query.tab.ovlp taeGut1.ucsc.masked.fa.len   all.cds.len > GALGA_TAEGU.axt.ortholog.algn
perl ../bin/ortholog_netAxt_coordinate_filter.pl  GALGA_TAEGU.axt.ortholog.algn 0.3 0.3  > GALGA_TAEGU.axt.ortholog.algn.filter
