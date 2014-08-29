#include "piler2.h"

static void WriteHit(FILE *f, const HitData &Hit, const PILE_INDEX_TYPE *PileIndexes)
	{
	const int TargetFrom = Hit.TargetFrom;
	const int QueryFrom = Hit.QueryFrom;

	int TargetContigFrom;
	const char *TargetLabel = GlobalToContig(TargetFrom, &TargetContigFrom);

	int QueryContigFrom;
	const char *QueryLabel = GlobalToContig(QueryFrom, &QueryContigFrom);

	const int TargetLength = Hit.TargetTo - TargetFrom + 1;
	const int QueryLength = Hit.QueryTo - QueryFrom + 1;

	const int QueryPileIndex = PileIndexes[QueryFrom];
	const int TargetPileIndex = PileIndexes[TargetFrom];

	const int QueryContigTo = QueryContigFrom + QueryLength - 1;
	const int TargetContigTo = TargetContigFrom + TargetLength - 1;

	const char Strand = Hit.Rev ? '-' : '+';

// GFF fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9
	fprintf(f, "%s\tpiler\thit\t%d\t%d\t0\t%c\t.\tTarget %s %d %d ; Piles %d %d\n",
	  QueryLabel,
	  QueryContigFrom + 1,
	  QueryContigTo + 1,
	  Strand,
	  TargetLabel,
	  TargetContigFrom + 1,
	  TargetContigTo + 1,
	  QueryPileIndex,
	  TargetPileIndex);
	}

void WriteImages(const char *FileName, const HitData *Hits, int HitCount,
  const PILE_INDEX_TYPE *PileIndexes)
	{
	FILE *f = OpenStdioFile(FileName, FILEIO_MODE_WriteOnly);
	for (int HitIndex = 0; HitIndex < HitCount; ++HitIndex)
		{
		const HitData &Hit = Hits[HitIndex];
		WriteHit(f, Hit, PileIndexes);
		}
	fclose(f);
	}
