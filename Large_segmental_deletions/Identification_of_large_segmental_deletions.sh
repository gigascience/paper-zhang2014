date

ort=./4species.ort
perl ./01.Slider.stat.pl $ort 5 1 > $ort.stat
perl ./02.Filter.flank.pl $ort $ort.stat 19 0.8 5  > $ort.stat.opt
perl ./03.PickUp.pl $ort.stat.opt  16  > $ort.stat.opt.STRCA
perl ./04.Merge.pl $ort.stat.opt.STRCA  13 0.8 > $ort.stat.opt.STRCA.nr
perl ./05.PseudoSuper.pl $ort.stat.opt.STRCA.nr > $ort.stat.opt.STRCA.nr.pse
perl ./06.Selected.stat.pl $ort.stat.opt.STRCA.nr.pse $ort 1 > $ort.stat.opt.STRCA.nr.pse.stat
perl ./07.obtain.rightSuper.pl $ort.stat.opt.STRCA.nr.pse.stat  13 0.8 > $ort.stat.opt.STRCA.nr.pse.stat.right
perl ./08.Marker.pseudoSuper.pl $ort.stat.opt.STRCA.nr.pse.stat.right $ort.stat.opt.STRCA.nr.pse  > $ort.stat.opt.STRCA.nr.pse.YN
perl ./09.Obtain.original.pl $ort.stat.opt.STRCA.nr.pse.stat.right $ort.stat.opt.STRCA.nr > $ort.stat.opt.STRCA.nr.pse.stat.original
	cat $ort.stat.opt.STRCA.nr.pse.stat.original $ort.stat.opt.STRCA.nr.pse.stat.right > $ort.stat.opt.STRCA.nr.pse.stat.All
perl ./10.Sort.segmentalDeletions.pl $ort.stat.opt.STRCA.nr $ort.stat.opt.STRCA.nr.pse.stat.All  > $ort.stat.opt.STRCA.nr.pse.stat.All.sort
perl ./06.Selected.stat.pl $ort.stat.opt.STRCA.nr.pse.stat.All.sort $ort 1 > $ort.stat.opt.STRCA.nr.pse.stat.All.sort.stat
perl ./06.Selected.stat.pl $ort.stat.opt.STRCA.nr.pse.stat.All.sort $ort 2 > $ort.stat.opt.STRCA.nr.pse.stat.All.sort.ort

date
