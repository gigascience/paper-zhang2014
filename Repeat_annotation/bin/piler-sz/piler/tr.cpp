#include "piler2.h"
#if defined(DEBUG) && defined(_MSC_VER)
#include <crtdbg.h>
#endif

#define GFFRecord GFFRecord2

/***
Find LTR families.

1. LTR candidates

    ------===--------------------===------------ genome
           ^----------------------^
                      Hit

Hit is candidate pair of LTRs bounding a candidate LINE if:
    (a) hit length >= MIN_LENGTH_LTR and <= MAX_LENGTH_LTR, and
    (b) offset is >= MIN_LENGTH_LINE and <= MAX_LENGTH_LINE.

2. Same family if a local alignment connects two LTR candidates
of similar length.


              Cand A                  Cand B
    ------===........===----------===........===----- genome
                      ^------------^
                            Hit
***/

static int MIN_LENGTH_LINE = 50;
static int MAX_LENGTH_LINE = 12000;
static int MIN_LENGTH_LTR = 50;
static int MAX_LENGTH_LTR = 2000;
static double MIN_LINE_RATIO = 0.9;
static int MIN_FAM_SIZE = 3;
static double MIN_HIT_LENGTH_RATIO = 0.5;
static int MIN_DIST_EDGE = 50000;

static EdgeList Edges;

static double Ratio(int i, int j)
	{
	if (i == 0 && j == 0)
		return 0;
	if (i < j)
		return (double) i / (double) j;
	else
		return (double) j / (double) i;
	}

static int GetHitLength(const HitData &Hit)
	{
	const int QueryHitLength = Hit.QueryTo - Hit.QueryFrom + 1;
	const int TargetHitLength = Hit.TargetTo - Hit.TargetFrom + 1;
	return (QueryHitLength + TargetHitLength)/2;
	}

static int GetLTRLength(const HitData &Hit)
	{
	const int QueryLTRLength = Hit.QueryTo - Hit.QueryFrom + 1;
	const int TargetLTRLength = Hit.TargetTo - Hit.TargetFrom + 1;
	return (QueryLTRLength + TargetLTRLength)/2;
	}

static int GetHitFrom(const HitData &Hit)
	{
	return min(Hit.QueryFrom, Hit.TargetFrom);
	}

static int GetHitTo(const HitData &Hit)
	{
	return max(Hit.QueryTo, Hit.TargetTo);
	}

static int GetLINELength(const HitData &Hit)
	{
	return GetHitTo(Hit) - GetHitFrom(Hit) + 1;
	}

static bool IsCandLTR(const HitData &Hit)
	{
	const int LTRLength = GetLTRLength(Hit);
	if (LTRLength < MIN_LENGTH_LTR || LTRLength > MAX_LENGTH_LTR)
		return false;

	const int LINELength = GetLINELength(Hit);
	if (LINELength < MIN_LENGTH_LINE || LINELength > MAX_LENGTH_LINE)
		return false;

	return true;
	}

static HitData *Cands;
static int CandCount = 0;
static int CandBufferSize = 0;
static void AddCand(const HitData &Hit, IIX &IntervalIndex)
	{
	if (CandCount >= CandBufferSize)
		{
		CandBufferSize += 10000;
		Cands = reall(Cands, HitData, CandBufferSize);
		}

	int From;
	int To;
	if (Hit.QueryFrom < Hit.TargetFrom)
		{
		From = Hit.QueryFrom;
		To = Hit.TargetTo;
		}
	else
		{
		From = Hit.TargetFrom;
		To = Hit.TargetTo;
		}

	IntervalIndex.AddGlobal(From, To, CandCount);
	Cands[CandCount++] = Hit;
	}

static bool TooClose(const GLIX &HitGlix, const HitData &Hit1, const HitData &Hit2)
	{
	const int Hit1From = Hit1.QueryFrom;
	const int Hit2From = Hit2.QueryFrom;
	int SeqFrom1;
	int SeqFrom2;
	const char *Label1 = HitGlix.GlobalToSeq(Hit1From, &SeqFrom1);
	const char *Label2 = HitGlix.GlobalToSeq(Hit2From, &SeqFrom2);
	if (0 != strcmp(Label1, Label2))
		return false;
	return iabs(SeqFrom2 - SeqFrom1) < MIN_DIST_EDGE;
	}

static bool IsEdge(const GLIX &HitGlix, const HitData &Hit, int i, int j)
	{
	if (i == j)
		return false;

	assert(i >= 0 && i < CandCount);
	assert(j >= 0 && j < CandCount);

	const HitData &Hit_i = Cands[i];
	const HitData &Hit_j = Cands[j];

	const int HitLength = GetHitLength(Hit);
	const int HitLength_i = GetHitLength(Hit_i);
	const int HitLength_j = GetHitLength(Hit_j);

	if (Ratio(HitLength, HitLength_i) < MIN_HIT_LENGTH_RATIO ||
	  Ratio(HitLength, HitLength_j) < MIN_HIT_LENGTH_RATIO ||
	  Ratio(HitLength_i, HitLength_j) < MIN_HIT_LENGTH_RATIO)
		return false;

	const int LINELength_i = GetLINELength(Hit_i);
	const int LINELength_j = GetLINELength(Hit_j);

	if (Ratio(LINELength_i, LINELength_j) < MIN_LINE_RATIO)
		return false;

	if (TooClose(HitGlix, Hit_i, Hit_j))
		return false;

	return true;
	}

static void FindEdges(const HitData &Hit, const GLIX &HitGlix, const IIX &IntervalIndex)
	{
	int *QueryMatches;
	int *TargetMatches;
	const int QueryMatchCount = IntervalIndex.LookupGlobal(Hit.QueryFrom, Hit.QueryTo, &QueryMatches);
	const int TargetMatchCount = IntervalIndex.LookupGlobal(Hit.TargetFrom, Hit.TargetTo, &TargetMatches);
	const int MatchCount = QueryMatchCount + TargetMatchCount;
	int *Matches = all(int, MatchCount);
	memcpy(Matches, QueryMatches, QueryMatchCount*sizeof(int));
	memcpy(Matches + QueryMatchCount, TargetMatches, TargetMatchCount*sizeof(int));

	for (int i = 0; i < MatchCount; ++i)
		{
		const int m = Matches[i];
		if (m < 0 || m > CandCount)
			Quit("m=%d count=%d", m, CandCount);
		}

	for (int i = 0; i < MatchCount; ++i)
		{
		const int CandIndex1 = Matches[i];
		for (int j = 0; j < i; ++j)
			{
			const int CandIndex2 = Matches[j];
			if (IsEdge(HitGlix, Hit, CandIndex1, CandIndex2))
				{
				EdgeData Edge;
				Edge.Node1 = CandIndex1;
				Edge.Node2 = CandIndex2;
				Edge.Rev = Hit.Rev;
				Edges.push_back(Edge);
				}
			}
		}
	}

static void WriteOutputFile(FILE *fOut, const GLIX &HitGlix, FamList &Fams)
	{
	GFFRecord Rec;
	Rec.Feature = "tr";
	Rec.Source = "piler";
	Rec.Score = 0;
	Rec.Strand = '.';
	Rec.Frame = -1;

	int FamIndex = 0;
	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamData *Fam = *p;
		for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
			{
			FamMemberData &FamMember = *q;
			int CandIndex = FamMember.PileIndex;
			assert(CandIndex >= 0 && CandIndex < CandCount);
			const HitData &Hit = Cands[CandIndex];

			const int GlobalFrom = GetHitFrom(Hit);
			const int GlobalTo = GetHitTo(Hit);
			const int Length = GlobalTo - GlobalFrom + 1;

			int SeqFrom;
			const char *Label = HitGlix.GlobalToSeq(GlobalFrom, &SeqFrom);
			int SeqTo = SeqFrom + Length - 1;

			Rec.SeqName = Label;
			Rec.Start = SeqFrom + 1;
			Rec.End = SeqTo + 1;
			Rec.Strand = (FamMember.Rev ? '-' : '+');

			char Attrs[1024];
			sprintf(Attrs, "Family %d ; Cand %d", FamIndex, CandIndex);

			Rec.Attrs = Attrs;

			WriteGFFRecord(fOut, Rec);
			}
		++FamIndex;
		}
	}

static void WriteCands(FILE *f, const GLIX &HitGlix)
	{
	GFFRecord Rec;
	for (int CandIndex = 0; CandIndex < CandCount; ++CandIndex)
		{
		const HitData &Hit = Cands[CandIndex];
		char AnnotBuffer[1024];
		HitToGFFRecord(HitGlix, Hit, Rec, AnnotBuffer);
		char s[4096];
		sprintf(s, "%s ; Cand %d", Rec.Attrs, CandIndex);
		Rec.Attrs = s;
		WriteGFFRecord(f, Rec);
		}
	}

void TR()
	{
#if defined(DEBUG) && defined(_MSC_VER)
	_CrtSetDbgFlag(0);	// too expensive
#endif

	const char *HitFileName = RequiredValueOpt("tr");
	const char *OutFileName = RequiredValueOpt("out");
	const char *CandFileName = ValueOpt("cand");

	const char *strMinTrSpacing = ValueOpt("mintrspacing");
	const char *strMaxTrSpacing = ValueOpt("maxtrspacing");
	const char *strMinTrLength = ValueOpt("mintrlength");
	const char *strMaxTrLength = ValueOpt("minspacingratio");
	const char *strMinFam = ValueOpt("minfam");
	const char *strMinHitRatio = ValueOpt("minhitratio");
	const char *strMinDistPairs = ValueOpt("mindistpairs");

	if (0 != strMinTrSpacing)
		MIN_LENGTH_LINE = atoi(strMinTrSpacing);
	if (0 != strMaxTrSpacing)
		MAX_LENGTH_LINE = atoi(strMaxTrSpacing);
	if (0 != strMinTrLength)
		MIN_LENGTH_LTR = atoi(strMinTrLength);
	if (0 != strMaxTrLength)
		MAX_LENGTH_LTR = atoi(strMaxTrLength);
	if (0 != strMinFam)
		MIN_FAM_SIZE = atoi(strMinFam);
	if (0 != strMinHitRatio)
		MIN_HIT_LENGTH_RATIO = atoi(strMinHitRatio);
	if (0 != strMinDistPairs)
		MIN_DIST_EDGE = atoi(strMinDistPairs);

	FILE *fHit = OpenStdioFile(HitFileName, FILEIO_MODE_ReadOnly);

	ProgressStart("Index hits");
	GLIX HitGlix;
	HitGlix.Init();
	HitGlix.FromGFFFile(fHit);
	HitGlix.MakeGlobalToLocalIndex();
	ProgressDone();

	const int GlobalLength = HitGlix.GetGlobalLength();
	IIX IntervalIndex;
	IntervalIndex.Init(GlobalLength);

	ProgressStart("Find candidate TRs");
	Rewind(fHit);
	GFFRecord Rec;
	while (GetNextGFFRecord(fHit, Rec))
		{
		HitData Hit;
		GFFRecordToHit(HitGlix, Rec, Hit);
		if (IsCandLTR(Hit))
			AddCand(Hit, IntervalIndex);
		}
	ProgressDone();

	Progress("%d candidates", CandCount);

	if (0 != CandFileName)
		{
		ProgressStart("Write candidates");
		FILE *fCand = OpenStdioFile(CandFileName, FILEIO_MODE_WriteOnly);
		WriteCands(fCand, HitGlix);
		ProgressDone();
		}

	ProgressStart("Make graph");
	Rewind(fHit);
	while (GetNextGFFRecord(fHit, Rec))
		{
		HitData Hit;
		GFFRecordToHit(HitGlix, Rec, Hit);
		FindEdges(Hit, HitGlix, IntervalIndex);
		}
	fclose(fHit);
	fHit = 0;

	ProgressDone();

	Progress("%d edges", (int) Edges.size());

	ProgressStart("Find families");
	FamList Fams;
	FindConnectedComponents(Edges, Fams, MIN_FAM_SIZE);
	ProgressDone();

	Progress("%d families", (int) Fams.size());

	FILE *fOut = OpenStdioFile(OutFileName, FILEIO_MODE_WriteOnly);
	WriteOutputFile(fOut, HitGlix, Fams);
	}
