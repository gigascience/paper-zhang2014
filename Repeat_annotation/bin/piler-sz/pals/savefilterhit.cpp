#include "pals.h"

static FILE *g_fFilterOut = 0;
static FILE *g_fFilterOutComp = 0;

extern int SeqLengthT;
extern int SeqLengthQ;
extern ContigData *ContigsT;
extern ContigData *ContigsQ;
extern int *ContigMapT;
extern int *ContigMapQ;
extern int ContigCountT;
extern int ContigCountQ;
extern bool FilterComp;

static int g_FilterHitCount = 0;
static int g_FilterHitCountComp = 0;

void SetFilterOutFile(FILE *f)
	{
	g_fFilterOut = f;
	}

void SetFilterOutFileComp(FILE *f)
	{
	g_fFilterOutComp = f;
	}

void CloseFilterOutFile()
	{
	fclose(g_fFilterOut);
	g_fFilterOut = 0;
	}

void CloseFilterOutFileComp()
	{
	fclose(g_fFilterOutComp);
	g_fFilterOutComp = 0;
	}

int GetFilterHitCount()
	{
	return g_FilterHitCount;
	}

int GetFilterHitCountComp()
	{
	return g_FilterHitCountComp;
	}

void SaveFilterHit(int qLo, int qHi, int DiagIndex)
	{
	if (FilterComp)
		{
		fprintf(g_fFilterOutComp, "%d;%d;%d\n", qLo, qHi, DiagIndex);
		++g_FilterHitCountComp;
		}
	else
		{
		fprintf(g_fFilterOut, "%d;%d;%d\n", qLo, qHi, DiagIndex);
		++g_FilterHitCount;
		}
	}

const void WriteDPHit(FILE *f, const DPHit &Hit, bool Comp)
	{
	int TargetFrom = Hit.abpos;
	int TargetTo = Hit.aepos;

	int QueryFrom;
	int QueryTo;
	if (Comp)
		{
//		QueryFrom = SeqLengthQ - Hit.bepos - 1;
//		QueryTo = SeqLengthQ - Hit.bbpos - 1;
// Another lazy hack: empirically found off-by-one
// complemented hits have query pos off-by-one, so
// fix by this change. Should figure out what's really
// going on.
		QueryFrom = SeqLengthQ - Hit.bepos;
		QueryTo = SeqLengthQ - Hit.bbpos;
		if (QueryFrom >= QueryTo)
			Quit("WriteDPHit: QueryFrom > QueryTo (comp)");
		}
	else
		{
		QueryFrom = Hit.bbpos;
		QueryTo = Hit.bepos;
		if (QueryFrom >= QueryTo)
			Quit("WriteDPHit: QueryFrom > QueryTo (not comp)");
		}

// DPHit coordinates sometimes over/underflow.
// This is a lazy hack to work around it, should really figure
// out what is going on.
	if (QueryFrom < 0)
		QueryFrom = 0;
	if (QueryTo >= SeqLengthQ)
		QueryTo = SeqLengthQ - 1;
	if (TargetFrom < 0)
		TargetFrom = 0;
	if (TargetTo >= SeqLengthT)
		TargetTo = SeqLengthT - 1;

// Take midpoint of segment -- lazy hack again, endpoints
// sometimes under / overflow
	const int TargetBin = (TargetFrom + TargetTo)/(2*CONTIG_MAP_BIN_SIZE);
	const int QueryBin = (QueryFrom + QueryTo)/(2*CONTIG_MAP_BIN_SIZE);
	const int BinCountT = (SeqLengthT + CONTIG_MAP_BIN_SIZE - 1)/CONTIG_MAP_BIN_SIZE;
	const int BinCountQ = (SeqLengthQ + CONTIG_MAP_BIN_SIZE - 1)/CONTIG_MAP_BIN_SIZE;
	if (TargetBin < 0 || TargetBin >= BinCountT)
		{
		Warning("Target bin out of range");
		return;
		}
	if (QueryBin < 0 || QueryBin >= BinCountQ)
		{
		Warning("Query bin out of range");
		return;
		}

	if (ContigMapT == 0 || ContigMapQ == 0)
		Quit("ContigMap = 0");

	const int TargetContigIndex = ContigMapT[TargetBin];
	const int QueryContigIndex = ContigMapQ[QueryBin];

	if (TargetContigIndex < 0 || TargetContigIndex >= ContigCountT)
		Quit("WriteDPHit: bad target contig index");

	if (QueryContigIndex < 0 || QueryContigIndex >= ContigCountT)
		Quit("WriteDPHit: bad query contig index");

	const int TargetLength = TargetTo - TargetFrom + 1;
	const int QueryLength = QueryTo - QueryFrom + 1;

	if (TargetLength < 0 || QueryLength < 0)
		Quit("WriteDPHit: Length < 0");

	const ContigData &TargetContig = ContigsT[TargetContigIndex];
	const ContigData &QueryContig = ContigsQ[QueryContigIndex];

	int TargetContigFrom = TargetFrom - TargetContig.From + 1;
	int QueryContigFrom = QueryFrom - QueryContig.From + 1;

	int TargetContigTo = TargetContigFrom + TargetLength - 1;
	int QueryContigTo = QueryContigFrom + QueryLength - 1;

	if (TargetContigFrom < 1)
		TargetContigFrom = 1;
	if (TargetContigTo > TargetContig.Length)
		TargetContigTo = TargetContig.Length;
	if (QueryContigFrom < 1)
		QueryContigFrom = 1;
	if (QueryContigTo > QueryContig.Length)
		QueryContigTo = QueryContig.Length;

	const char *TargetLabel = TargetContig.Label;
	const char *QueryLabel = QueryContig.Label;

	const char Strand = Comp ? '-' : '+';

// GFF Fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9
	fprintf(f, "%s\tpals\thit\t%d\t%d\t%d\t%c\t.\tTarget %s %d %d; maxe %.2g\n",
	  QueryLabel,
	  QueryContigFrom,
	  QueryContigTo,
	  Hit.score,
	  Strand,
	  TargetLabel,
	  TargetContigFrom,
	  TargetContigTo,
	  Hit.error);
	}

void WriteDPHits(FILE *f, const DPHit *DPHits, int DPHitCount, bool Comp)
	{
	for (int i = 0; i < DPHitCount; ++i)
		{
		const DPHit &Hit = DPHits[i];
		WriteDPHit(f, Hit, Comp);
		}
	}
