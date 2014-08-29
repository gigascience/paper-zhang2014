#include "piler2.h"

static void WritePile(FILE *f, const PileData &Pile, int PileIndex)
	{
	int ContigFrom;
	const char *ContigLabel = GlobalToContig(Pile.From, &ContigFrom);
	const int Length = Pile.To - Pile.From + 1;
	const int ContigTo = ContigFrom + Length - 1;
	const char Strand = Pile.Rev ? '-' : '+';

// GFF fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9
	fprintf(f, "%s\tpiler\tpile\t%d\t%d\t0\t%c\t.\tPile %d\n",
	  ContigLabel,
	  ContigFrom + 1,
	  ContigTo + 1,
	  Strand,
	  PileIndex);
	}

void WritePiles(const char *FileName, const PileData *Piles, int PileCount)
	{
	FILE *f = OpenStdioFile(FileName, FILEIO_MODE_WriteOnly);
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		const PileData &Pile = Piles[PileIndex];
		WritePile(f, Pile, PileIndex);
		}
	fclose(f);
	}
