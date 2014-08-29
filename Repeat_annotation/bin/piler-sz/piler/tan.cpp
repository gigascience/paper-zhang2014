#include "piler2.h"

#define GFFRecord GFFRecord2

static int MIN_HIT_COUNT = 2;
static double MAX_FRACT_MARGIN = 0.05;
static double MIN_RATIO = 0.5;

struct TanPile
	{
	char *Label;
	int From;
	int To;
	HitData *Hits;
	int HitCount;
	};
static TanPile *Piles;
static int PileCount;
static int PileBufferSize;
static int PyramidIndex;
FILE *fOut;
FILE *fPyramid;
FILE *fMotif;

static inline int min3(int i, int j, int k)
	{
	return min(i, min(j, k));
	}

static inline int max3(int i, int j, int k)
	{
	return max(i, max(j, k));
	}

static void TouchPiles(int PileIndex)
	{
	if (PileIndex < PileBufferSize)
		{
		if (PileIndex >= PileCount)
			PileCount = PileIndex + 1;
		return;
		}

	int NewPileBufferSize = PileBufferSize + 10000;
	TanPile *NewPiles = all(TanPile, NewPileBufferSize);
	zero(NewPiles, TanPile, NewPileBufferSize);
	memcpy(NewPiles, Piles, PileCount*sizeof(TanPile));
	Piles = NewPiles;
	PileBufferSize = NewPileBufferSize;
	PileCount = PileIndex + 1;
	}

static void AssignHit(int PileIndex, const char *Label, int QueryFrom, int QueryTo,
  int TargetFrom, int TargetTo, bool Rev)
	{
	TanPile &Pile = Piles[PileIndex];

	int HitIndex = Pile.HitCount;
	HitData &Hit = Pile.Hits[HitIndex];

	Hit.QueryFrom = QueryFrom;
	Hit.QueryTo = QueryTo;
	Hit.TargetFrom = TargetFrom;
	Hit.TargetTo = TargetTo;
	Hit.Rev = Rev;

	++(Pile.HitCount);
	}

static void AddHit(int PileIndex, const char *Label, int QueryFrom, int QueryTo,
  int TargetFrom, int TargetTo, bool Rev)
	{
	TouchPiles(PileIndex);

	TanPile &Pile = Piles[PileIndex];
	if (0 == Pile.HitCount)
		{
		Pile.Label = strsave(Label);
		Pile.From = min(QueryFrom, TargetFrom);
		Pile.To = max(QueryTo, TargetTo);
		}
	else
		{
		if (0 != strcmp(Label, Pile.Label))
			Quit("Labels disagree");
		Pile.From = min3(Pile.From, QueryFrom, TargetFrom);
		Pile.To = max3(Pile.To, QueryTo, TargetTo);
		}
	++(Pile.HitCount);
	}

bool TandemPair(const HitData &Hit1, const HitData &Hit2)
	{
	int Length1 = (Hit1.QueryTo - Hit1.QueryFrom + Hit1.TargetTo- Hit1.TargetFrom)/2;
	int Length2 = (Hit2.QueryTo - Hit2.QueryFrom + Hit2.TargetTo - Hit2.TargetFrom)/2;
	int ShorterLength = min(Length1, Length2);
	int LongerLength = max(Length1, Length2);
	if ((double) ShorterLength / (double) LongerLength < MIN_RATIO)
		return false;

	int StartDist = iabs(Hit1.TargetFrom - Hit2.TargetFrom);
	int EndDist = iabs(Hit1.QueryTo - Hit2.QueryTo);

	double StartMargin = (double) StartDist / (double) ShorterLength;
	double EndMargin = (double) EndDist / (double) ShorterLength;
	return StartMargin <= MAX_FRACT_MARGIN && EndMargin <= MAX_FRACT_MARGIN;
	}

static void WritePyramid(int PyramidIndex, const char *Label, int From, int To)
	{
	if (0 == fPyramid)
		return;

	GFFRecord Rec;
	Rec.Source = "piler";
	Rec.Feature = "pyramid";
	Rec.Score = 0;
	Rec.Frame = -1;
	Rec.Strand = '.';
	Rec.SeqName = Label;
	Rec.Start = From + 1;
	Rec.End = To + 1;

	char s[32];
	sprintf(s, "PyramidIndex %d", PyramidIndex);
	Rec.Attrs = s;

	WriteGFFRecord(fPyramid, Rec);
	}

static void InferMotif(int PyramidIndex, const TanPile &Pile, FamData *Fam)
	{
	const int MAX_PAIRS = 1024;
	int DiagDists[MAX_PAIRS];
	int PairCount = 0;
	int MinDiagDist = -1;
	for (PtrFamData q1 = Fam->begin(); q1 != Fam->end(); ++q1)
		{
		FamMemberData &FamMember1 = *q1;
		int HitIndex1 = FamMember1.PileIndex;
		if (HitIndex1 < 0 || HitIndex1 >= Pile.HitCount)
			Quit("Hit index out of range");
		const HitData &Hit1 = Pile.Hits[HitIndex1];
		int Diag1Start = Hit1.TargetFrom - Hit1.QueryFrom;
		int Diag1End = Hit1.TargetTo - Hit1.QueryTo;
		int Diag1 = (Diag1Start + Diag1End)/2;

		PtrFamData q2 = q1;
		for (++q2; q2 != Fam->end(); ++q2)
			{
			FamMemberData &FamMember2 = *q2;
			int HitIndex2 = FamMember2.PileIndex;
			if (HitIndex2 < 0 || HitIndex2 >= Pile.HitCount)
				Quit("Hit index out of range");
			const HitData &Hit2 = Pile.Hits[HitIndex2];

			int Diag2Start = Hit2.TargetFrom - Hit2.QueryFrom;
			int Diag2End = Hit2.TargetTo - Hit2.QueryTo;
			int Diag2 = (Diag2Start + Diag2End)/2;

			int DiagDist = iabs(Diag1 - Diag2);
			if (-1 == MinDiagDist || DiagDist < MinDiagDist)
				MinDiagDist = DiagDist;
			DiagDists[PairCount++] = DiagDist;
			if (PairCount == MAX_PAIRS)
				goto Done;
			}
		}
Done:
// Find all dists that are no more than 10% bigger than MinDist.
// The average of these distances is the estimated repeat length.
	int Count = 0;
	int Sum = 0;
	int MaxCandidateDist = (MinDiagDist*110)/100;
	for (int i = 0; i < PairCount; ++i)
		{
		const int Dist = DiagDists[i];
		if (Dist <= MaxCandidateDist)
			{
			Sum += Dist;
			++Count;
			}
		}
	if (0 == Count)
		Quit("Huh?");

	const int EstimatedRepeatLength = Sum/Count;
	Log("\n");
	Log("Pyramid %d: min dist = %d ", PyramidIndex, MinDiagDist);
	Log(" Count=%d Sum=%d Estd=%d\n", Count, Sum, EstimatedRepeatLength);

	GFFRecord Rec;
	Rec.Source = "piler";
	Rec.Feature = "tandemmotif";
	Rec.Score = 0;
	Rec.Frame = -1;
	Rec.SeqName = Pile.Label;
	Rec.Strand = '.';

// By definition, a Pyramid is set of hits for which QueryTo
// and TargetFrom values are approximately equal.
// We arbitrarily choose the canonical motif to end
// at QueryTo. We output this motif and the Target motifs
// to which it aligns.
	FamMemberData &FamMember = *(Fam->begin());
	int HitIndex = FamMember.PileIndex;
	if (HitIndex < 0 || HitIndex >= Pile.HitCount)
		Quit("Hit index out of range");
	const HitData &Hit = Pile.Hits[HitIndex];

	const int MotifQueryTo = Hit.QueryTo;
	const int MotifQueryFrom = MotifQueryTo - EstimatedRepeatLength + 1;
	const int TargetTo = Hit.TargetTo;
	const int TargetFrom = TargetTo - EstimatedRepeatLength + 1;

	char s[1024];
	sprintf(s, "Target %s %d %d ; Pyramid %d",
		Pile.Label,
		TargetFrom + 1,
		TargetTo + 1,
		PyramidIndex);

	Rec.Start = MotifQueryFrom + 1;
	Rec.End = MotifQueryTo + 1;
	Rec.Attrs = s;

	WriteGFFRecord(fMotif, Rec);

	for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
		{
		FamMemberData &FamMember = *q;
		int HitIndex = FamMember.PileIndex;
		if (HitIndex < 0 || HitIndex >= Pile.HitCount)
			Quit("Hit index out of range");
		const HitData &Hit = Pile.Hits[HitIndex];

		const int To = Hit.TargetTo;
		const int From = To - EstimatedRepeatLength + 1;

		char s[1024];
		sprintf(s, "Target %s %d %d ; Pyramid %d",
		  Pile.Label,
		  MotifQueryFrom + 1,
		  MotifQueryTo + 1,
		  PyramidIndex);

		Rec.Start = From + 1;
		Rec.End = To + 1;
		Rec.Attrs = s;

		WriteGFFRecord(fMotif, Rec);
		}
	}

static void LogPyramid(int PyramidIndex, const TanPile &Pile, FamData *Fam)
	{
	Log("\n");
	Log("Pyramid %d\n", PyramidIndex);

	Log(
"     Label   QStart1     QEnd1   TStart1     TEnd1   QStart1     QEnd1   TStart1     TEnd1    Diag   Start     End\n");
	Log(
"----------  --------  --------  --------  --------  --------  --------  --------  --------  ------  ------  ------\n");
	for (PtrFamData q1 = Fam->begin(); q1 != Fam->end(); ++q1)
		{
		FamMemberData &FamMember1 = *q1;
		int HitIndex1 = FamMember1.PileIndex;
		if (HitIndex1 < 0 || HitIndex1 >= Pile.HitCount)
			Quit("Hit index out of range");
		const HitData &Hit1 = Pile.Hits[HitIndex1];
		int Diag1Start = Hit1.TargetFrom - Hit1.QueryFrom;
		int Diag1End = Hit1.TargetTo - Hit1.QueryTo;
		int Diag1 = (Diag1Start + Diag1End)/2;

		PtrFamData q2 = q1;
		for (++q2; q2 != Fam->end(); ++q2)
			{
			FamMemberData &FamMember2 = *q2;
			int HitIndex2 = FamMember2.PileIndex;
			if (HitIndex2 < 0 || HitIndex2 >= Pile.HitCount)
				Quit("Hit index out of range");
			const HitData &Hit2 = Pile.Hits[HitIndex2];

			int Diag2Start = Hit2.TargetFrom - Hit2.QueryFrom;
			int Diag2End = Hit2.TargetTo - Hit2.QueryTo;
			int Diag2 = (Diag2Start + Diag2End)/2;

			int DiagDist = iabs(Diag1 - Diag2);

			int StartDist = iabs(Hit1.TargetFrom - Hit2.TargetFrom);
			int EndDist = iabs(Hit1.QueryTo - Hit2.QueryTo);
			Log("%10.10s  %8d  %8d  %8d  %8d  %8d  %8d  %8d  %8d  %6d",
				Pile.Label,
				Hit1.QueryFrom,
				Hit1.QueryTo,
				Hit1.TargetFrom,
				Hit1.TargetTo,
				Hit2.QueryFrom,
				Hit2.QueryTo,
				Hit2.TargetFrom,
				Hit2.TargetTo,
				DiagDist);
			Log("  %6d", StartDist);
			Log("  %6d", EndDist);
			Log("\n");
			}
		}
	}

static void FindPyramids(int PileIndex)
	{
	const TanPile &Pile = Piles[PileIndex];
	const int HitCount = Pile.HitCount;
	if (HitCount < MIN_HIT_COUNT)
		return;

	EdgeList Edges;
	EdgeData Edge;
	Edge.Rev = false;
	const HitData *Hits = Pile.Hits;
	for (int HitIndex1 = 0; HitIndex1 < HitCount; ++HitIndex1)
		{
		const HitData &Hit1 = Hits[HitIndex1];
		Edge.Node1 = HitIndex1;
		for (int HitIndex2 = 0; HitIndex2 < HitIndex1; ++HitIndex2)
			{
			const HitData &Hit2 = Hits[HitIndex2];
			if (TandemPair(Hit1, Hit2))
				{
				Edge.Node2 = HitIndex2;
				Edges.push_back(Edge);
				}
			}
		}

	FamList Fams;
	FindConnectedComponents(Edges, Fams, MIN_HIT_COUNT);

	if (0 == Fams.size())
		return;

	GFFRecord Rec;
	Rec.Source = "piler";
	Rec.Feature = "hit";
	Rec.Score = 0;
	Rec.Frame = -1;
	Rec.SeqName = Pile.Label;

	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamData *Fam = *p;
		if (0 != fMotif)
			InferMotif(PyramidIndex, Pile, Fam);
		LogPyramid(PyramidIndex, Pile, Fam);

		int PyramidFrom = -1;
		int PyramidTo = -1;

		for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
			{
			FamMemberData &FamMember = *q;
			int HitIndex = FamMember.PileIndex;
			if (HitIndex < 0 || HitIndex >= Pile.HitCount)
				Quit("Hit index out of range");
			const HitData &Hit = Pile.Hits[HitIndex];

			char s[1024];
			sprintf(s, "Target %s %d %d ; Pile %d ; Pyramid %d",
			  Pile.Label,
			  Hit.TargetFrom + 1,
			  Hit.TargetTo + 1,
			  PileIndex,
			  PyramidIndex);

			Rec.Strand = (Hit.Rev ? '-' : '+');
			Rec.Start = Hit.QueryFrom + 1;
			Rec.End = Hit.QueryTo + 1;
			Rec.Attrs = s;

			WriteGFFRecord(fOut, Rec);

			if (PyramidFrom == -1)
				PyramidFrom = min(Hit.QueryFrom, Hit.TargetFrom);
			else
				PyramidFrom = min3(PyramidFrom, Hit.QueryFrom, Hit.TargetFrom);

			if (PyramidTo == -1)
				PyramidTo = max(Hit.QueryTo, Hit.TargetTo);
			else
				PyramidTo = max3(PyramidTo, Hit.QueryTo, Hit.TargetTo);
			}
		WritePyramid(PyramidIndex, Pile.Label, PyramidFrom, PyramidTo);
		++PyramidIndex;
		}
	}

void Tan()
	{
// Image file annotated with from-to pile indexes
// Produced by:
//		piler2 -trs banded_hits.gff -images mainband_images.gff
	const char *HitFileName = RequiredValueOpt("tan");
	const char *OutFileName = RequiredValueOpt("out");
	const char *PyramidFileName = ValueOpt("pyramid");
	const char *MotifFileName = ValueOpt("motif");
	const char *strMinHits = ValueOpt("minhits");
	const char *strMaxMargin = ValueOpt("maxmargin");
	const char *strMinRatio = ValueOpt("minratio");

	if (0 != strMinHits)
		MIN_HIT_COUNT = atoi(strMinHits);
	if (0 != strMaxMargin)
		MAX_FRACT_MARGIN = atof(strMaxMargin);
	if (0 != strMinRatio)
		MIN_RATIO = atof(strMinRatio);

	FILE *fInput = OpenStdioFile(HitFileName);

	ProgressStart("Initialize piles");
	GFFRecord Rec;
	int HitCount = 0;
	while (GetNextGFFRecord(fInput, Rec))
		{
		if (0 != strcmp(Rec.Feature, "hit"))
			continue;

		int QueryPileIndex = -1;
		int TargetPileIndex = -1;
		ParsePilesAttrs(Rec.Attrs, &QueryPileIndex, &TargetPileIndex);
		if (QueryPileIndex != TargetPileIndex)
			continue;

		char TargetLabel[128];
		int TargetStart;
		int TargetEnd;
		ParseTargetAttrs(Rec.Attrs, TargetLabel, sizeof(TargetLabel), &TargetStart, &TargetEnd);
		if (0 != strcmp(Rec.SeqName, TargetLabel))
			Quit("Labels don't match");

		const int QueryFrom = Rec.Start - 1;
		const int QueryTo = Rec.End - 1;
		const int TargetFrom = TargetStart - 1;
		const int TargetTo = TargetEnd - 1;
		const bool Rev = (Rec.Strand == '-');

		AddHit(QueryPileIndex, Rec.SeqName, QueryFrom, QueryTo, TargetFrom, TargetTo, Rev);
		++HitCount;
		}
	ProgressDone();

	Progress("%d hits, %d piles", HitCount, PileCount);

	ProgressStart("Allocate piles");
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		TanPile &Pile = Piles[PileIndex];
		Pile.Hits = all(HitData, Pile.HitCount);
		Pile.HitCount = 0;
		}
	ProgressDone();

	ProgressStart("Assign hits to piles");
	Rewind(fInput);
	while (GetNextGFFRecord(fInput, Rec))
		{
		if (0 != strcmp(Rec.Feature, "hit"))
			continue;

		int QueryPileIndex = -1;
		int TargetPileIndex = -1;
		ParsePilesAttrs(Rec.Attrs, &QueryPileIndex, &TargetPileIndex);
		if (QueryPileIndex != TargetPileIndex)
			continue;

		char TargetLabel[128];
		int TargetStart;
		int TargetEnd;
		ParseTargetAttrs(Rec.Attrs, TargetLabel, sizeof(TargetLabel), &TargetStart, &TargetEnd);
		if (0 != strcmp(Rec.SeqName, TargetLabel))
			Quit("Labels don't match");

		const int QueryFrom = Rec.Start - 1;
		const int QueryTo = Rec.End - 1;
		const int TargetFrom = TargetStart - 1;
		const int TargetTo = TargetEnd - 1;
		const bool Rev = (Rec.Strand == '-');

		AssignHit(QueryPileIndex, Rec.SeqName, QueryFrom, QueryTo, TargetFrom, TargetTo, Rev);
		}
	ProgressDone();

	fOut = OpenStdioFile(OutFileName, FILEIO_MODE_WriteOnly);
	fPyramid = (0 == PyramidFileName ? 0 : OpenStdioFile(PyramidFileName, FILEIO_MODE_WriteOnly));
	fMotif = (0 == PyramidFileName ? 0 : OpenStdioFile(MotifFileName, FILEIO_MODE_WriteOnly));

	ProgressStart("Find pyramids");
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		FindPyramids(PileIndex);
	int PyramidCount = PyramidIndex;
	ProgressDone();

	Progress("%d pyramids", PyramidCount);
	}
