#include "piler2.h"

#define MAX(i, j)	((i) >= (j) ? (i) : (j))
#define MIN(i, j)	((i) <= (j) ? (i) : (j))

const double MIN_OVERLAP = 0.05;
const int MAX_HITS = 8;
const int MAX_STR = 256;
const int MAP_CHARS = 20;
const double MAX_MARGIN = 0.05;
const int EDGE_BASES = 100;
const int MIN_OVERLAP_EDGE = 32;

struct AnnotHit
	{
	int Overlap;
	int RepIndex;
	};
static AnnotHit AHs[MAX_HITS];
static int AnnotHitCount;

static char Str[MAX_STR+1];
static int StrPos;

static const RepData *g_Reps;
static int g_RepCount;
static bool g_Rev;
static int g_Mid;

static int InRegion(int ContigFrom, int ContigTo, int Pos)
	{
	if (Pos >= ContigFrom && Pos <= ContigTo)
		return true;
	if (Pos < ContigFrom && ContigFrom - Pos <= MAX_MARGIN)
		return true;
	if (Pos > ContigTo && Pos - ContigTo <= MAX_MARGIN)
		return true;
	return false;
	}

static int CmpAH(const void *a1, const void *a2)
	{
	const AnnotHit *h1 = (const AnnotHit *) a1;
	const AnnotHit *h2 = (const AnnotHit *) a2;
	int i1 = h1->RepIndex;
	int i2 = h2->RepIndex;
	assert(i1 >= 0 && i1 < g_RepCount);
	assert(i2 >= 0 && i2 < g_RepCount);
	if (g_Rev)
		return g_Reps[i2].ContigFrom - g_Reps[i1].ContigFrom;
	return g_Reps[i1].ContigFrom - g_Reps[i2].ContigFrom;
	}

static int CmpAHEdge(const void *a1, const void *a2)
	{
	const AnnotHit *h1 = (const AnnotHit *) a1;
	const AnnotHit *h2 = (const AnnotHit *) a2;
	int i1 = h1->RepIndex;
	int i2 = h2->RepIndex;
	assert(i1 >= 0 && i1 < g_RepCount);
	assert(i2 >= 0 && i2 < g_RepCount);

	const RepData &Rep1 = g_Reps[i1];
	const RepData &Rep2 = g_Reps[i2];

	int df1 = iabs(Rep1.ContigFrom - g_Mid);
	int df2 = iabs(Rep2.ContigFrom - g_Mid);

	int dt1 = iabs(Rep1.ContigTo - g_Mid);
	int dt2 = iabs(Rep2.ContigTo - g_Mid);

	int d1 = MIN(df1, dt1);
	int d2 = MIN(df2, dt2);

	return d1 - d2;
	}

static void SafeCatChar(char c)
	{
	if (StrPos >= MAX_STR)
		return;
	Str[StrPos++] = c;
	Str[StrPos] = 0;
	}

static void SafeCat(const char *s)
	{
	while (char c = *s++)
		{
		if (StrPos >= MAX_STR)
			break;
		Str[StrPos++] = c;
		}
	Str[StrPos] = 0;
	}

static int GetAnnots(const char *Label, int ContigFrom, int ContigTo,
  const RepData *Reps, int RepCount, int MinOverlap)
	{
	int AnnotHitCount = 0;
	for (int RepIndex = 0; RepIndex < RepCount; ++RepIndex)
		{
		const RepData &Rep = Reps[RepIndex];
		if (0 != strcmp(Label, Rep.ContigLabel))
			continue;
		int ov = Overlap(ContigFrom, ContigTo, Rep.ContigFrom, Rep.ContigTo);
		if (ov < MinOverlap)
			continue;

	// Unconditionally accept if not maxed out
		if (AnnotHitCount < MAX_HITS)
			{
			AHs[AnnotHitCount].Overlap = ov;
			AHs[AnnotHitCount].RepIndex = RepIndex;
			++AnnotHitCount;
			}
		else
			{
		// Overwrite shortest hit if this is longer
			int SmallestOverlap = AHs[0].Overlap;
			int SmallestIndex = 0;
			for (int i = 1; i < MAX_HITS; ++i)
				{
				if (AHs[i].Overlap < SmallestOverlap)
					{
					SmallestOverlap = AHs[i].Overlap;
					SmallestIndex = 0;
					}
				}
			if (ov > SmallestOverlap)
				{
				AHs[SmallestIndex].RepIndex = RepIndex;
				AHs[SmallestIndex].Overlap = ov;
				}
			}
		}
	return AnnotHitCount;
	}

static int PosToCharIndex(int RegionFrom, int RegionTo, int Pos, int MapChars)
	{
	if (MapChars <= 1)
		return 0;

	int RegionLength = RegionTo - RegionFrom + 1;
	if (RegionLength <= 1)
		return 0;

	if (Pos < RegionFrom)
		return 0;
	if (Pos >= RegionTo)
		return MapChars - 1;

	int CharIndex = ((Pos - RegionFrom)*MapChars)/RegionLength;
	if (CharIndex < 0 || CharIndex >= MapChars)
		Quit("PosToCharIndex messed up");
	return CharIndex;
	}

static void RevStr()
	{
	for (int i = 0; i < MAP_CHARS/2; ++i)
		{
		char c1 = Str[i];
		char c2 = Str[MAP_CHARS-i-1];
		Str[i] = c2;
		Str[MAP_CHARS-i-1] = c1;
		}
	}

const char *MakeAnnotEdge(const char *Label, int SeqFrom, int SeqTo, bool Rev,
  const RepData *Reps, int RepCount)
	{
	StrPos = 0;
	for (int i = 0; i < MAP_CHARS; ++i)
		SafeCatChar('-');

	const int Mid = (SeqFrom + SeqTo)/2;
	int ContigFrom = SeqFrom - EDGE_BASES/2;
	int ContigTo = SeqFrom + EDGE_BASES/2;

	int From = ContigFrom;
	int To = ContigTo;
	if (From < 0)
		From = 0;

	AnnotHitCount = GetAnnots(Label, From, To, Reps, RepCount, MIN_OVERLAP_EDGE);
	if (0 == AnnotHitCount)
		return Str;

// Global vars needed by CmpAHEdge
	g_Rev = Rev;
	g_Reps = Reps;
	g_RepCount = RepCount;
	g_Mid = Mid;
// Sort by edge
	qsort((void *) AHs, AnnotHitCount, sizeof(AnnotHit), CmpAHEdge);

	for (int AnnotIndex = 0; AnnotIndex < AnnotHitCount; ++AnnotIndex)
		{
		const int RepIndex = AHs[AnnotIndex].RepIndex;
		const RepData &Rep = Reps[RepIndex];

		bool LeftEnd = false;
		bool RightEnd = false;
		int RepFrom = Rep.RepeatFrom;
		if (-1 != RepFrom)
			{
			int RepTo = Rep.RepeatTo;
			int RepLeft = Rep.RepeatLeft;
			int RepLength = RepTo + RepLeft - 1;
			if (RepLength <= 0)
				RepLength = 9999;	// hack to avoid div by 0

			int RepContigFrom = Rep.ContigFrom;
			int RepContigTo = Rep.ContigTo;
			if (Rep.Rev)
				{
				int Tmp = RepFrom;
				RepFrom = RepLeft;
				RepLeft = Tmp;
				}
			const double LeftMargin = (double) RepFrom / RepLength;
			const double RightMargin = (double) RepLeft / RepLength;
			bool LeftInRegion = InRegion(ContigFrom, ContigTo, Rep.ContigFrom);
			bool RightInRegion = InRegion(ContigFrom, ContigTo, Rep.ContigTo);
			LeftEnd = (LeftInRegion && LeftMargin <= MAX_MARGIN);
			RightEnd = (RightInRegion && RightMargin <= MAX_MARGIN);
			}

		int MapFrom = PosToCharIndex(ContigFrom, ContigTo, Rep.ContigFrom, MAP_CHARS);
		int MapTo = PosToCharIndex(ContigFrom, ContigTo, Rep.ContigTo, MAP_CHARS);

		const char cLower = 'a' + AnnotIndex;
		const char cUpper = 'A' + AnnotIndex;

		if (LeftEnd)
			Str[MapFrom] = cUpper;
		else
			Str[MapFrom] = cLower;

		for (int i = MapFrom + 1; i <= MapTo - 1; ++i)
			Str[i] = cLower;

		if (RightEnd)
			Str[MapTo] = cUpper;
		else
			Str[MapTo] = cLower;

		SafeCat(" ");
		SafeCat(Rep.RepeatName);

		if (Rep.RepeatFrom >= 0)
			{
			int FullRepLength = Rep.RepeatTo + Rep.RepeatLeft;
			int RepMissing = Rep.RepeatFrom + Rep.RepeatLeft;
			double Pct = ((FullRepLength - RepMissing)*100.0)/FullRepLength;
			char s[32];
			sprintf(s, "(%.0f%%)", Pct);
			SafeCat(s);
			}
		}

	if (Rev)
		RevStr();
	return Str;
	}

const char *MakeAnnot(const char *Label, int SeqFrom, int SeqTo, bool Rev,
  const RepData *Reps, int RepCount)
	{
	int ContigFrom = SeqFrom;
	int ContigTo = SeqTo;
	int Length = ContigTo - ContigFrom + 1;
	const int MinOverlap = (int) (Length*MIN_OVERLAP);

	StrPos = 0;
	for (int i = 0; i < MAP_CHARS; ++i)
		SafeCatChar('-');

	AnnotHitCount = GetAnnots(Label, ContigFrom, ContigTo, Reps, RepCount,
	  MinOverlap);
	if (0 == AnnotHitCount)
		return Str;

// Global vars needed by CmpAH
	g_Rev = Rev;
	g_Reps = Reps;
	g_RepCount = RepCount;
// Sort by start pos
	qsort((void *) AHs, AnnotHitCount, sizeof(AnnotHit), CmpAH);

	for (int AnnotIndex = 0; AnnotIndex < AnnotHitCount; ++AnnotIndex)
		{
		const int RepIndex = AHs[AnnotIndex].RepIndex;
		const RepData &Rep = Reps[RepIndex];
		const int From = MAX(Rep.ContigFrom, ContigFrom);
		const int To = MIN(Rep.ContigTo, ContigTo);

		bool LeftEnd = false;
		bool RightEnd = false;
		int RepFrom = Rep.RepeatFrom;
		if (-1 != RepFrom)
			{
			int RepTo = Rep.RepeatTo;
			int RepLeft = Rep.RepeatLeft;
			int RepLength = RepTo + RepLeft - 1;
			if (RepLength <= 0)
				RepLength = 9999;	// hack to avoid div by 0

			if (Rep.ContigFrom < ContigFrom)
				RepFrom += (ContigFrom - Rep.ContigFrom);
			if (Rep.ContigTo > ContigTo)
				RepTo -= Rep.ContigTo - ContigTo;

			const double LeftMargin = (double) RepFrom / RepLength;
			const double RightMargin = (double) RepLeft / RepLength;
			LeftEnd = (LeftMargin <= MAX_MARGIN);
			RightEnd = (RightMargin <= MAX_MARGIN);
			}

		int MapFrom = ((From - ContigFrom)*MAP_CHARS)/Length;
		int MapTo = ((To - ContigFrom)*MAP_CHARS)/Length;

		if (Rev)
			{
			int Tmp = MapFrom;
			MapFrom = MAP_CHARS - MapTo - 1;
			MapTo = MAP_CHARS - Tmp - 1;
			}

		if (MapFrom < 0 || MapFrom >= MAP_CHARS || MapTo < 0 || MapTo >= MAP_CHARS)
			Quit("MakeAnnot: failed to map");

		const char cLower = 'a' + AnnotIndex;
		const char cUpper = 'A' + AnnotIndex;

		if (LeftEnd)
			Str[MapFrom] = cUpper;
		else
			Str[MapFrom] = cLower;

		for (int i = MapFrom + 1; i <= MapTo - 1; ++i)
			Str[i] = cLower;

		if (RightEnd)
			Str[MapTo] = cUpper;
		else
			Str[MapTo] = cLower;

		SafeCat(" ");
		SafeCat(Rep.RepeatName);

		if (Rep.RepeatFrom >= 0)
			{
			int FullRepLength = Rep.RepeatTo + Rep.RepeatLeft;
			int RepMissing = Rep.RepeatFrom + Rep.RepeatLeft;
			if (ContigFrom > Rep.ContigFrom)
				RepMissing += ContigFrom - Rep.ContigFrom;
			if (Rep.ContigTo > ContigTo)
				RepMissing += Rep.ContigTo - ContigTo;
			double Pct = ((FullRepLength - RepMissing)*100.0)/FullRepLength;
			char s[32];
			sprintf(s, "(%.0f%%)", Pct);
			SafeCat(s);
			}
		}

	return Str;
	}
