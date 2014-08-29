#include "pals.h"
#include "forkmer.h"

#define	TRACE		0

extern char *SeqT;
static int Tlen;
static char *SeqQ;
static int Qlen;
static bool Self;
static bool Comp;
static int MinMatch;
static int MaxError;
static int TubeOffset;
static int TubeWidth;
static int MinKmersPerHit;
static TubeState *Tubes;
static int MaxActiveTubes;
static int MaxKmerDist;

#define CalcDiagIndex(t, q)			(Tlen - (t) + (q))
#define CalcTubeIndex(DiagIndex)	((DiagIndex)/TubeOffset)

static void AddHit(int TubeIndex, int qLo, int qHi)
	{
#if	TRACE
	Log("AddHit(Tube=%d, qLo=%d, qHi=%d)\n",
	  Tlen - TubeIndex*TubeOffset, qLo, qHi + k);
#endif

	SaveFilterHit(qLo, qHi + k, Tlen - TubeIndex*TubeOffset);
	}

// Called when end of a tube is reached
// A point in the tube -- the point with maximal q -- is (Tlen-1,q-1).
static void TubeEnd(int q)
	{
	int DiagIndex = CalcDiagIndex(Tlen - 1, q - 1);
	int TubeIndex = CalcTubeIndex(DiagIndex);

	TubeState *Tube = Tubes + TubeIndex%MaxActiveTubes;
#if	TRACE
	Log("TubeEnd(%d) DiagIndex=%d TubeIndex=%d Count=%d\n",
	  q, DiagIndex, TubeIndex, Tube->Count);
#endif
	if (Tube->Count >= MinKmersPerHit)
		AddHit(TubeIndex, Tube->qLo, Tube->qHi);

	Tube->Count = 0;
	}

// Called when q=Qlen - 1 to flush any hits in each tube.
static void TubeFlush(int TubeIndex)
	{
	TubeState *Tube = Tubes + TubeIndex%MaxActiveTubes;
#if	TRACE
	Log("TubeFlush(TubeIndex=%d) Count=%d\n",
	  TubeIndex, Tube->Count);
#endif
	if (Tube->Count < MinKmersPerHit)
		return;

	AddHit(TubeIndex, Tube->qLo, Tube->qHi);
	Tube->Count = 0;
	}

static void HitTube(int TubeIndex, int q)
	{
	TubeState *Tube = Tubes + TubeIndex%MaxActiveTubes;

#if	TRACE
	Log("HitTube(TubeIndex=%d, q=%d) Count=%d\n",
	  TubeIndex, q, Tube->Count);
#endif

	if (0 == Tube->Count)
		{
		Tube->Count = 1;
		Tube->qLo = q;
		Tube->qHi = q;
		return;
		}

	if (q - Tube->qHi > MaxKmerDist)
		{
		if (Tube->Count >= MinKmersPerHit)
			AddHit(TubeIndex, Tube->qLo, Tube->qHi);

		Tube->Count = 1;
		Tube->qLo = q;
		Tube->qHi = q;
		return;
		}

	++(Tube->Count);
	Tube->qHi = q;
	}

// Found a common k-mer SeqT[t] and SeqQ[q].
static inline void CommonKmer(int t, int q)
	{
//	assert(StringToCode(SeqT+t, k) == StringToCode(SeqQ+q, k));
	if (Self && (Comp ? (q < Tlen - t) : (q <= t)))
		return;

#if	TRACE
	Log("CommonKmer(%d,%d) SeqT=%.*s SeqQ=%.*s\n",
	  t, q, k, SeqT+t, k, SeqQ+q);
#endif

	int DiagIndex = CalcDiagIndex(t, q);
	int TubeIndex = CalcTubeIndex(DiagIndex);

#if	TRACE
	Log("HitTube(TubeIndex=%d, t=%d, q=%d)\n", TubeIndex, t, q);
#endif
	HitTube(TubeIndex, q);

// Hit in overlapping tube preceding this one?
	if (DiagIndex%TubeOffset < MaxError)
		{
		if (0 == TubeIndex)
			TubeIndex = MaxActiveTubes - 1;
		else
			--TubeIndex;
		assert(TubeIndex >= 0);
#if	TRACE
		Log("HitTube(TubeIndex=%d, t=%d, q=%d) [overlap]\n", TubeIndex, t, q);
#endif
		HitTube(TubeIndex, q);
		}
	}

void Filter(/* char *T_, */ int Tlen_, char *B_, int Qlen_, bool Self_, bool Comp_,
  const int *Finger, const int *Pos, const FilterParams &FP)
	{
//	SeqT = T_;
	SeqQ = B_;
	Tlen = Tlen_;
	Qlen = Qlen_;
	Self = Self_;
	Comp = Comp_;

	MinMatch = FP.SeedLength;
	MaxError = FP.SeedDiffs;
	TubeOffset = FP.TubeOffset;

// Ukonnen's Lemma
	MinKmersPerHit = MinMatch + 1 - k*(MaxError + 1);

// Maximum distance between SeqQ positions of two k-mers in a match
// (More stringent bounds may be possible, but not a big problem
// if two adjacent matches get merged).
	MaxKmerDist = MinMatch - k;

	TubeWidth = TubeOffset + MaxError;

	if (TubeOffset < MaxError)
		{
		Log("TubeOffset < MaxError\n");
		exit(1);
		}
	if (MinKmersPerHit <= 0)
		{
		Log("MinKmersPerHit <= 0\n");
		exit(1);
		}

	MaxActiveTubes = (Tlen + TubeWidth - 1)/TubeOffset + 1;
	Tubes = all(TubeState, MaxActiveTubes);
	zero(Tubes, TubeState, MaxActiveTubes);

// Ticker tracks cycling of circular list of active tubes.
	int Ticker = TubeWidth;
	FOR_EACH_KMER(SeqQ, Qlen, q, c)
		{
		int From = Finger[c];
		int To = Finger[c+1];
		for (int i = From; i < To; ++i)
			{
			CommonKmer(Pos[i], q);
			}
		if (0 == --Ticker)
			{
			TubeEnd(q);
			Ticker = TubeOffset;
			}
		}
	END_FOR_EACH_KMER(SeqQ, Qlen, q, c)

	TubeEnd(Qlen - 1);

	int DiagFrom = CalcDiagIndex(Tlen - 1, Qlen - 1) - TubeWidth;
	int DiagTo = CalcDiagIndex(0, Qlen - 1) + TubeWidth;

	int TubeFrom = CalcTubeIndex(DiagFrom);
	if (TubeFrom < 0)
		TubeFrom = 0;

	int TubeTo = CalcTubeIndex(DiagTo);

	for (int TubeIndex = TubeFrom; TubeIndex <= TubeTo; ++TubeIndex)
		TubeFlush(TubeIndex);

	freemem(Tubes);
	}
