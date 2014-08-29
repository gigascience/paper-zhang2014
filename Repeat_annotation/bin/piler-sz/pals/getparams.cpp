#include "pals.h"

/***
Generate default aligner parameters given:
	minimum hit length.
	minimum fractional identity.
	sequence lengths.
	maximum memory.
	self alignment?
***/

const int DEFAULT_LENGTH = 400;
const double DEFAULT_MIN_ID = 0.94;
const double RAM_FRACT = 0.80;

/***
For minimum word length, choose k=4 arbitrarily.
For max, k=16 definitely won't work with 32-bit ints
because 4^16 = 2^32 = 4GB.
k=15 might be OK, but would have to look carefully at
boundary cases, which I haven't done.
k=14 is definitely safe, so set this as upper bound.
***/
const int MIN_WORD_LENGTH = 4;
const int MAX_WORD_LENGTH = 14;
const int MAX_AVG_INDEX_LIST_LENGTH = 10;
const int TUBE_OFFSET_DELTA = 32;

static double FilterMemRequired(int SeqLengthT, const FilterParams &FP)
	{
	const double Words = pow4d(FP.WordSize);
	const int TubeWidth = FP.TubeOffset + FP.SeedDiffs;
	const double MaxActiveTubes = (SeqLengthT + TubeWidth - 1)/FP.TubeOffset + 1;
	const double Tubes = MaxActiveTubes*sizeof(TubeState);
	const double Finger = 4*Words;
	const double Pos = 4*SeqLengthT;
	return Finger + Pos + Tubes;
	}

double AvgIndexListLength(int SeqLengthT, const FilterParams &FP)
	{
	return SeqLengthT / pow4d(FP.WordSize);
	}

double TotalMemRequired(int SeqLengthT, int SeqLengthQ, bool Self,
  const FilterParams &FP)
	{
	const double Filter = FilterMemRequired(SeqLengthT, FP);
	const double Seq = Self ? SeqLengthT : SeqLengthT + SeqLengthQ;
	return Filter + Seq;
	}

static void DefParams(int MinHitLength, double MinId, int SeqLengthT, int SeqLengthQ,
  bool Self, double MaxMem, FilterParams *ptrFP, DPParams *ptrDP)
	{
	if (MinId < 0 || MinId > 1.0)
		Quit("DefParams: bad MinId=%g", MinId);
	if (MinHitLength <= 4)
		Quit("DefParams: bad MinHitLength=%d", MinHitLength);

	const char *strTubeOffset = ValueOpt("tubeoffset");
	const int TubeOffset = (0 == strTubeOffset) ? -1 : atoi(strTubeOffset);

// Lower bound on word length k by requiring manageable index.
// Given kmer occurs once every 4^k positions.
// Hence average number of index entries is i = N/(4^k) for random
// string of length N.
// Require i <= I, then k > log_4(N/i).
	const double dSeqLengthA = (double) SeqLengthT;
	const int MinWordSize = (int) (log4(dSeqLengthA) - log4(MAX_AVG_INDEX_LIST_LENGTH) + 0.5);

// First choice is that filter criteria are same as DP criteria,
// but this may not be possible.
	int SeedLength = MinHitLength;
	int SeedDiffs = (int) (MinHitLength*(1.0 - MinId));

// Find filter valid filter parameters,
// starting from preferred case.
	int WordSize = -1;
	for (;;)
		{
		int MinWords = -1;
		for (WordSize = MAX_WORD_LENGTH; WordSize >= MinWordSize; --WordSize)
			{
			ptrFP->WordSize = WordSize;
			ptrFP->SeedLength = SeedLength;
			ptrFP->SeedDiffs = SeedDiffs;
			ptrFP->TubeOffset = TubeOffset > 0 ? TubeOffset : ptrFP->SeedDiffs + TUBE_OFFSET_DELTA;

			double Mem = TotalMemRequired(SeqLengthT, SeqLengthQ, Self, *ptrFP);
			if (MaxMem > 0 && Mem > MaxMem)
				{
				Log("Parameters n=%d k=%d e=%d, mem=%.0f Mb > maxmem=%.0f Mb\n",
				  ptrFP->SeedLength,
				  ptrFP->WordSize,
				  ptrFP->SeedDiffs,
				  Mem/1e6,
				  MaxMem/1e6);
				MinWords = -1;
				continue;
				}

			MinWords = MinWordsPerFilterHit(SeedLength, WordSize, SeedDiffs);
			if (MinWords <= 0)
				{
				Log("Parameters n=%d k=%d e=%d, B=%d\n",
				  ptrFP->SeedLength,
				  ptrFP->WordSize,
				  ptrFP->SeedDiffs,
				  MinWords);
				MinWords = -1;
				continue;
				}

			const double Len = AvgIndexListLength(SeqLengthT, *ptrFP);
			if (Len > MAX_AVG_INDEX_LIST_LENGTH)
				{
				Log("Parameters n=%d k=%d e=%d, B=%d avgixlen=%g > max = %d\n",
				  ptrFP->SeedLength,
				  ptrFP->WordSize,
				  ptrFP->SeedDiffs,
				  MinWords,
				  Len,
				  MAX_AVG_INDEX_LIST_LENGTH);
				MinWords = -1;
				continue;
				}
			break;
			}
		if (MinWords > 0)
			break;

	// Failed to find filter parameters, try
	// fewer errors and shorter seed.
		if (SeedLength >= MinHitLength/4)
			{
			SeedLength /= 2;
			continue;
			}

		if (SeedDiffs > 0)
			{
			--SeedDiffs;
			continue;
			}
		
		Quit("Failed to find filter parameters");
		}

	ptrDP->MinHitLength = MinHitLength;
	ptrDP->MinId = MinId;
	}

/***
Alignment parameters can be specified in three ways:

(1) All defaults.
(2) By -length and -pctid only.
(3) All parameters specified:
	-wordsize -seedlength -seeddiffs -length -pctid

Optional parameters:
	-maxmem			(Default = 80% of RAM, 0 = no maximum)
	-tube			(Tube offset, Default = 32)
***/
void GetParams(int SeqLengthT, int SeqLengthQ, bool Self,
  FilterParams *ptrFP, DPParams *ptrDP)
	{
	const char *strLength = ValueOpt("length");
	const char *strPctId = ValueOpt("pctid");
	const char *strWordSize = ValueOpt("wordsize");
	const char *strSeedLength = ValueOpt("seedlength");
	const char *strSeedErrors = ValueOpt("seeddiffs");

	const char *strMaxMem = ValueOpt("maxmem");
	const char *strTubeOffset = ValueOpt("tubeoffset");

	const double MaxMem = (0 == strMaxMem) ? GetRAMSize()*RAM_FRACT : atof(strMaxMem);
	const int TubeOffset = (0 == strTubeOffset) ? -1 : atoi(strTubeOffset);

// All parameters specified
	if (0 != strWordSize || 0 != strSeedLength || 0 != strSeedErrors)
		{
		if (0 == strWordSize || 0 == strSeedLength || 0 == strSeedErrors ||
		  0 == strLength || 0 == strPctId)
			Quit("Missing one or more of: -wordsize, -seedlength, -seeddiffs, -length, -pctid");

		ptrFP->SeedDiffs = atoi(strSeedErrors);
		ptrFP->SeedLength = atoi(strSeedLength);
		ptrFP->WordSize = atoi(strWordSize);
		ptrFP->TubeOffset = TubeOffset > 0 ? TubeOffset : ptrFP->SeedDiffs + TUBE_OFFSET_DELTA;

		ptrDP->MinHitLength = atoi(strLength);
		ptrDP->MinId = atoi(strPctId)/100.0;
		}

// -length and -pctid
	else if (0 != strLength || 0 != strPctId)
		{
		if (0 == strLength || 0 == strPctId)
			Quit("Missing option -length or -pctid");

		int Length = atoi(strLength);
		double MinId = atof(strPctId)/100.0;

		DefParams(Length, MinId, SeqLengthT, SeqLengthQ, Self, MaxMem, ptrFP, ptrDP);
		}

// All defaults
	else
		{
		DefParams(DEFAULT_LENGTH, DEFAULT_MIN_ID, SeqLengthT, SeqLengthQ,
		  Self, MaxMem, ptrFP, ptrDP);
		}
	}
