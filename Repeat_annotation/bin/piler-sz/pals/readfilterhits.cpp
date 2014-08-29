#include "pals.h"

FilterHit *ReadFilterHits(FILE *f, int Count)
	{
	if (0 == Count)
		return 0;

	int Ok = fseek(f, 0, SEEK_SET);
	long Pos = ftell(f);
	if (Pos != 0)
		Quit("ReadFilterHits: rewind failed, fseek=%d ftell=%ld errno=%d",
		  Ok, Pos, errno);

	FilterHit *FilterHits = all(FilterHit, Count);
	for (int HitIndex = 0; HitIndex < Count; ++HitIndex)
		{
		FilterHit &Hit = FilterHits[HitIndex];
		int n = fscanf(f, "%d;%d;%d\n", &Hit.QFrom, &Hit.QTo, &Hit.DiagIndex);
		if (n != 3)
			Quit("Failed to read filter hit %d of %d, fscanf=%d",
			  HitIndex, Count, n);
		}
	return FilterHits;
	}
