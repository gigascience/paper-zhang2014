## Get the ortholog information for filtered gene list
perl ../bin/fishInWinter.pl ./GALGA_TAEGU.axt.ortholog.algn.filter ./GALGA_TAEGU.axt.ortholog > GALGA_TAEGU.ortholog
perl ../bin/fishInWinter.pl  ./taeGut1-galGal3.net.ortholog.algn.filter ./aeGut1-galGal3.net.ortholog > TAEGU_GALGA.ortholog

## Find reciprocal ortholog
perl ../bin/reciprocal_netAxt_corr_ortholog.pl GALGA_TAEGU.ortholog  TAEGU_GALGA.ortholog  0.3 > GALGA_TAEGU.ortholog.cor
perl ./bin/check_pepLength_exonNum.pl all.pep.len gene_exonNum.tab GALGA_TAEGU.ortholog.cor  > GALGA_TAEGU.ortholog.cor.pepLen_exonNum

## Add human gene information (Ensembl release-60)
perl ../bin/check_pepLength_exonNum_2.pl all.pep.len HUMAN.pep.len HUMAN.gene_exonNum.tab gene_exonNum.tab  GALGA_TAEGU.ortholog.cor.pepLen_exonNum GALGA_HUMAN.ortholog > GALGA_TAEGU.ortholog.cor.pepLen_exonNum.detail
perl ../bin/solar_align_rate_ortholog_2.pl all.pep.len hg_gal.hg_tae.solar GALGA_TAEGU.ortholog.cor.pepLen_exonNum.detail > GALGA_TAEGU.ortholog.cor.pepLen_exonNum.detail.algn2
