#include "pals.h"

// for getpid:
#if	WIN32
#include <process.h>
#else
#include <sys/types.h>
#include <unistd.h>
#endif

int k;
ContigData *ContigsT = 0;
ContigData *ContigsQ = 0;
int SeqLengthT = -1;
int SeqLengthQ = -1;
int *ContigMapT = 0;
int *ContigMapQ = 0;
int ContigCountT = -1;
int ContigCountQ = -1;
bool FilterComp = false;
int Diameter = 50000;
bool Banded = false;
char *SeqT;

static const char *GetFilterOutFileName(const char *strFilterOut, const char *Ext)
	{
	if (0 == strFilterOut)
		{
		static char s[32];
		sprintf(s, "./_pf%d", getpid());
		strFilterOut = s;
		}
	size_t n = strlen(strFilterOut) + strlen(Ext) + 1;
	char *FileName = all(char, (int) n);
	strcpy(FileName, strFilterOut);
	strcat(FileName, Ext);
	assert(strlen(FileName) == n - 1);
	return FileName;
	}

void PALS()
	{
	const char *strSelf = ValueOpt("self");
	const char *strTarget = ValueOpt("target");
	const char *strQuery = ValueOpt("query");
	const char *strOutFileName = ValueOpt("out");
	const char *strFilterOut = ValueOpt("filterout");
	const char *strDiameter = ValueOpt("diameter");
	bool FwdOnly = FlagOpt("fwdonly");

	if (0 != strDiameter)
		{
		Diameter = atoi(strDiameter);
		Banded = true;
		}

	const bool Self = (0 != strSelf);
	const bool Pair = (0 != strTarget && 0 != strQuery);
	if (!Self && !Pair)
		CommandLineError("Must specify either -self or both -target and -query");
	if (Self && Pair)
		CommandLineError("Not valid to specify both -self and -query");
	if (Banded && !Self)
		CommandLineError("-diameter (banded search) requires -self");

	char *SeqQ = 0;

	if (Self)
		{
		ProgressStart("Reading sequence");
		SeqT = ReadMFA(strSelf, &SeqLengthT, &ContigsT, &ContigCountT, &ContigMapT);
		ProgressDone();

		Progress("Sequence length %d bases (%.0f Mb), %d contigs",
		  SeqLengthT,
		  SeqLengthT/1e6,
		  ContigCountT);

		SeqQ = SeqT;
		SeqLengthQ = SeqLengthT;
		ContigsQ = ContigsT;
		ContigCountQ = ContigCountT;
		ContigMapQ = ContigMapT;
		}
	else
		{
		ProgressStart("Reading target");
		SeqT = ReadMFA(strTarget, &SeqLengthT, &ContigsT, &ContigCountT, &ContigMapT);
		ProgressDone();

		Progress("Target length %d bases (%.0f Mb), %d contigs",
		  SeqLengthT,
		  SeqLengthT/1e6,
		  ContigCountT);

		ProgressStart("Reading query");
		SeqQ = ReadMFA(strQuery, &SeqLengthQ, &ContigsQ, &ContigCountQ, &ContigMapQ);
		ProgressDone();

		Progress("Query length %d bases (%.0f Mb), %d contigs",
		  SeqLengthQ, 
		  SeqLengthQ/1e6,
		  ContigCountQ);
		}

	if (Diameter > SeqLengthQ)
		Diameter = SeqLengthQ;

	int EffectiveSeqLengthQ = Diameter;
	int EffectiveSeqLengthT = Diameter;

	FilterParams FP;
	DPParams DP;
	GetParams(EffectiveSeqLengthT, EffectiveSeqLengthQ, Self, &FP, &DP);

	k = FP.WordSize;

	const double SeedPctId = (1.0 - (double) FP.SeedDiffs / (double) FP.SeedLength)*100.0;
	const double MemRequired = TotalMemRequired(SeqLengthT, SeqLengthQ, Self, FP);
	const double AvgIndexList = AvgIndexListLength(SeqLengthT, FP);

	Log("Filter parameters:\n");
	Log("   Word size       %d\n", FP.WordSize);
	Log("   Seed length     %d\n", FP.SeedLength);
	Log("   Seed diffs      %d\n", FP.SeedDiffs);
	Log("   Seed min id     %.1f%%\n", SeedPctId);
	Log("   Tube offset     %d\n", FP.TubeOffset);
	if (AvgIndexList > 2)
		Log("   Avg index list  %.1f\n", AvgIndexList);
	else
		Log("   Avg index list  %.2g\n", AvgIndexList);
	Log("DP parameters:\n");
	Log("   Min length      %d\n", DP.MinHitLength);
	Log("   Min id          %.0f%%\n", DP.MinId*100.0);
	Log("Estd. memory       %.0f Mb\n", MemRequired/1e6);
	Log("RAM                %.0f Mb\n", GetRAMSize()/1e6);

	bool NeedIndex = !Banded;
	int *Finger = 0;
	int *Pos = 0;
	if (NeedIndex)
		{
		ProgressStart("Indexing target");
		MakeIndex(SeqT, SeqLengthT, &Finger, &Pos);
		ProgressDone();

#if	DEBUG
		ProgressStart("Check index");
		CheckIndex(SeqT, SeqLengthT, Finger, Pos);
		ProgressDone();
#endif
		}

	const char *strFilterOutFileName = GetFilterOutFileName(strFilterOut, ".f.tmp");
	FILE *fFilterOut = OpenStdioFile(strFilterOutFileName, FILEIO_MODE_ReadWrite);
	SetFilterOutFile(fFilterOut);

	ProgressStart("Filtering");
	FilterComp = false;
	if (Banded)
		FilterB(SeqLengthT, SeqQ, SeqLengthQ, FP, Diameter, FilterComp);
	else
		Filter(SeqLengthT, SeqQ, SeqLengthQ, Self, FilterComp, Finger, Pos, FP);
	ProgressDone();

	const int FilterHitCount = GetFilterHitCount();
	Progress("%d filter hits", FilterHitCount);

	FILE *fFilterOutComp = 0;
	int FilterHitCountComp = 0;
	const char *strFilterOutFileNameComp = 0;
	if (!FwdOnly)
		{
		if (!Banded)
		// Complement query.
		// Note that if we're aligning to self, we're also complementing target.
		// But this doesn't matter; everything we need is in the index.
			Complement(SeqQ, SeqLengthQ);

		strFilterOutFileNameComp = GetFilterOutFileName(strFilterOut, ".r.tmp");
		fFilterOutComp = OpenStdioFile(strFilterOutFileNameComp, FILEIO_MODE_ReadWrite);
		SetFilterOutFileComp(fFilterOutComp);

		ProgressStart("Filtering complement");
		FilterComp = true;
		if (Banded)
			FilterB(SeqLengthT, SeqQ, SeqLengthQ, FP, Diameter, FilterComp);
		else
			Filter(SeqLengthT, SeqQ, SeqLengthQ, Self, FilterComp, Finger, Pos, FP);
		ProgressDone();

		FilterHitCountComp = GetFilterHitCountComp();
		Progress("%d filter hits ", GetFilterHitCountComp());

		if (!Banded)
	// De-complement query
			Complement(SeqQ, SeqLengthQ);
		}

	if (NeedIndex)
		FreeIndex(Finger, Pos);

	ProgressStart("Read filter hits");
	FilterHit *FilterHits = ReadFilterHits(fFilterOut, FilterHitCount);
	CloseFilterOutFile();
	if (0 == strFilterOut)
		remove(strFilterOutFileName);
	ProgressDone();

	ProgressStart("Merge filter hits");
	int TrapCount;
	Trapezoid *Traps = MergeFilterHits(SeqT, SeqLengthT, SeqQ, SeqLengthQ,
	  Self, FilterHits, FilterHitCount, FP, &TrapCount);
	ProgressDone();

	freemem(FilterHits);
	FilterHits = 0;

	const int SumLengths = SumTrapLengths(Traps);
	Progress("%d trapezoids, total length %d", TrapCount, SumLengths);

	ProgressStart("Align filter hits");
	int DPHitCount;
	DPHit *DPHits = AlignTraps(SeqT, SeqLengthT, SeqQ, SeqLengthQ,
	  Traps, TrapCount, false, DP, &DPHitCount);
	ProgressDone();

	FILE *fOut = stdout;
	if (0 != strOutFileName)
		fOut = OpenStdioFile(strOutFileName, FILEIO_MODE_WriteOnly);
	WriteDPHits(fOut, DPHits, DPHitCount, false);

	if (FwdOnly)
		{
		if (!Self)
			freemem(SeqT);
		freemem(SeqQ);
		SeqQ = 0;
		SeqT = 0;
		}
	free(Traps);
	Traps = 0;

	const int LengthDP = SumDPLengths(DPHits, DPHitCount);
	Progress("%d DP hits, total length %d", DPHitCount, LengthDP);

	free(DPHits);
	DPHits = 0;

	if (!FwdOnly)
		{
		ProgressStart("Read filter hits (complement)");
		FilterHit *FilterHitsComp = ReadFilterHits(fFilterOutComp, FilterHitCountComp);
		CloseFilterOutFileComp();
		if (0 == strFilterOut)
			remove(strFilterOutFileNameComp);
		ProgressDone();

	// If we're aligning to self, need a second copy of the query
	// so that we can complement it (can't do it in place, because
	// SeqQ is a pointer alias of SeqT).
		char *SeqQComp;
		if (Self)
			{
			SeqQComp = all(char, SeqLengthQ);
			memcpy(SeqQComp, SeqQ, SeqLengthQ);
			}
		else
			SeqQComp = SeqQ;
		Complement(SeqQComp, SeqLengthQ);

		ProgressStart("Merge filter hits");
		int TrapCountComp;
		Trapezoid *TrapsComp = MergeFilterHits(SeqT, SeqLengthT, SeqQComp, SeqLengthQ,
		  Self, FilterHitsComp, FilterHitCountComp, FP, &TrapCountComp);
		ProgressDone();

		freemem(FilterHitsComp);
		FilterHitsComp = 0;

		const int LengthTraps = SumTrapLengths(TrapsComp);
		Progress("%d trapezoids, total length %d", TrapCountComp, LengthTraps);

		ProgressStart("Align filter hits");
		int DPHitCountComp;
		DPHit *DPHitsComp = AlignTraps(SeqT, SeqLengthT, SeqQComp, SeqLengthQ,
		  TrapsComp, TrapCountComp, false, DP, &DPHitCountComp);
		ProgressDone();

		if (Self)
			freemem(SeqQComp);
		if (!Self)
			freemem(SeqT);
		freemem(SeqQ);
		free(TrapsComp);
		SeqQ = 0;
		SeqT = 0;
		TrapsComp = 0;

		const int LengthDP = SumDPLengths(DPHitsComp, DPHitCountComp);
		Progress("%d DP hits, total length %d", DPHitCountComp, LengthDP);

		WriteDPHits(fOut, DPHitsComp, DPHitCountComp, true);

		free(DPHitsComp);
		DPHitsComp = 0;
		}
	}
