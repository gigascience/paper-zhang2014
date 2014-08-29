#include "pals.h"
#include "forkmer.h"

// FilterB: Banded search of SeqQ
// (There is no SeqT).
// TODO: Add complemented band (currently only supports fwdonly).

//#undef assert
//#define assert(exp) (void)( (exp) || (my_assert(#exp, __FILE__, __LINE__), 0) )
//
//static void my_assert(const char *exp, const char *file, int line)
//	{
//	Quit("Assert failed %s %s %d", exp, file, line);
//	}

#define	TRACE		0

// static char *SeqT;
static int Tlen;
static char *SeqQ;
static int Qlen;
static int MinMatch;
static int MaxError;
static int TubeOffset;
static int TubeWidth;
static int MinKmersPerHit;
static TubeState *Tubes;
static int MaxActiveTubes;
static int MaxKmerDist;

//==============================================================
// Start rolling index stuff
//==============================================================

struct INDEX_ENTRY
	{
	int Kmer;	// for debugging only
	int Pos;
	INDEX_ENTRY *Next;
	INDEX_ENTRY *Prev;
	};

static INDEX_ENTRY *Entries;
static INDEX_ENTRY **Heads;
static INDEX_ENTRY **Tails;
static INDEX_ENTRY *FreeEntries;
static int KmerIndexCount;
static int KmerWindowCount;

static void AddToFreeList(INDEX_ENTRY *E)
	{
#if	DEBUG
	E->Kmer = -2;
	E->Pos = -2;
#endif

	E->Prev = 0;
	E->Next = FreeEntries;
	if (0 != FreeEntries)
		FreeEntries->Prev = E;
	FreeEntries = E;
	}

static void AllocateIndex(int Diameter, int k)
	{
	KmerIndexCount = pow4(k);
	KmerWindowCount = Diameter - k + 1;

	Entries = all(INDEX_ENTRY, KmerWindowCount);

	zero(Entries, INDEX_ENTRY, KmerWindowCount);

	Heads = all(INDEX_ENTRY *, KmerIndexCount);
	Tails = all(INDEX_ENTRY *, KmerIndexCount);

	zero(Heads, INDEX_ENTRY *, KmerIndexCount);
	zero(Tails, INDEX_ENTRY *, KmerIndexCount);

	for (int i = 0; i < KmerWindowCount; ++i)
		AddToFreeList(&(Entries[i]));
	}

static void AddToIndex(int Kmer, int Pos)
	{
	if (-1 == Kmer)
		return;

	assert(Kmer >= 0 && Kmer < KmerIndexCount);
	assert(FreeEntries != 0);

	INDEX_ENTRY *Entry = FreeEntries;
	FreeEntries = FreeEntries->Next;
	if (FreeEntries != 0)
		FreeEntries->Prev = 0;

	INDEX_ENTRY *Tail = Tails[Kmer];

// Insert after tail of list
	Entry->Kmer = Kmer;
	Entry->Pos = Pos;
	Entry->Next = 0;
	Entry->Prev = Tail;

	if (0 == Tail)
		Heads[Kmer] = Entry;
	else
		Tail->Next = Entry;
	Tails[Kmer] = Entry;
	}

static inline int GetKmer(const char *Seq, int Pos)
	{
	return StringToCode(Seq + Pos, k);
	}

#define DeclareListPtr(p)	INDEX_ENTRY *p

static inline INDEX_ENTRY *GetListPtr(int Kmer)
	{
	assert(Kmer >= 0 && Kmer < KmerIndexCount);
	return Heads[Kmer];
	}

static inline bool NotEndOfList(INDEX_ENTRY *p)
	{
	return p != 0;
	}

static inline INDEX_ENTRY *GetListNext(INDEX_ENTRY *p)
	{
	return p->Next;
	}

static inline int GetListPos(INDEX_ENTRY *p)
	{
	return p->Pos;
	}

static void ValidateIndex(const char *Seq, int WindowStart, int WindowEnd)
	{
	int FreeCount = 0;
	for (INDEX_ENTRY *p = FreeEntries; p != 0; p = p->Next)
		{
		if (++FreeCount > KmerWindowCount)
			Quit("Validate index failed free count");

		if (p->Kmer != -2 || p->Pos != -2)
			Quit("Validate index failed free != -2");

		const INDEX_ENTRY *pNext = p->Next;
		if (0 != pNext && pNext->Prev != p)
			Quit("Validate index failed free pNext->Prev != p");

		const INDEX_ENTRY *pPrev = p->Prev;
		if (0 != pPrev && pPrev->Next != p)
			Quit("Validate index failed free pPrev->Next != p");
		}

	for (int Pos = WindowStart; Pos < WindowEnd; ++Pos)
		{
		const int Kmer = GetKmer(Seq, Pos);
		if (-1 == Kmer)
			continue;
		for (DeclareListPtr(p) = GetListPtr(Kmer); NotEndOfList(p); p = GetListNext(p))
			{
			const int HitPos = GetListPos(p);
			if (HitPos == Pos)
				goto Found;
			}
		Quit("Validate index failed, pos not found");
	Found:;
		}

	int IndexedCount = 0;
	for (int Kmer = 0; Kmer < KmerIndexCount; ++Kmer)
		{
		INDEX_ENTRY *Head = Heads[Kmer];
		INDEX_ENTRY *Tail = Tails[Kmer];
		if (Head != 0 && Head->Prev != 0)
			Quit("Head->Prev != 0");
		if (Tail != 0 && Tail->Next != 0)
			Quit("Tail->Next != 0");
		if ((Head == 0) != (Tail == 0))
			Quit("Head / tail");
		int PrevHitPos = -1;
		int ListIndex = 0;
		for (DeclareListPtr(p) = GetListPtr(Kmer); NotEndOfList(p); p = GetListNext(p))
			{
			++IndexedCount;
			if (IndexedCount > KmerWindowCount)
				Quit("Valiate index failed, count");

			const INDEX_ENTRY *pNext = p->Next;
			if (Kmer != p->Kmer)
				Quit("Validate index failed, kmer");

			if (0 != pNext && pNext->Prev != p)
				Quit("Validate index failed pNext->Prev != p");

			const INDEX_ENTRY *pPrev = p->Prev;
			if (0 != pPrev && pPrev->Next != p)
				Quit("Validate index failed pPrev->Next != p");

			const int HitPos = GetListPos(p);
			if (HitPos < WindowStart || HitPos > WindowEnd)
				Quit("ValidateIndex failed, hit not in window kmer=%d %s",
				  Kmer, CodeToString(Kmer, k));

			int IsTail = (p->Next == 0);
			if (HitPos < PrevHitPos)
				Quit("Validate index failed, sort order Kmer=%d HitPos=%d PrevHitPos=%d ListIndex=%d IsTail=%d",
				  Kmer, HitPos, PrevHitPos, ListIndex, IsTail);

			PrevHitPos = HitPos;
			++ListIndex;
			}
		}
	if (IndexedCount > KmerWindowCount)
		Quit("Validate index failed, count [2]");
	}

static void LogLocations(int Kmer)
	{
	Log("LogLocations(%d %s)", Kmer, CodeToString(Kmer, k));
	for (DeclareListPtr(p) = GetListPtr(Kmer); NotEndOfList(p); p = GetListNext(p))
		Log(" [%d]=%d", p->Pos, StringToCode(SeqQ + p->Pos, k));
	}

// Pos not required; used for sanity check
static void DeleteFirstInstanceFromIndex(int Kmer, int Pos)
	{
	if (-1 == Kmer)
		return;

	assert(Kmer >= 0 && Kmer < KmerIndexCount);

	INDEX_ENTRY *E = Heads[Kmer];

	if (E == 0)
		Quit("DFI Kmer=%d %s Pos=%d", Kmer, CodeToString(Kmer, k), Pos);
//	assert(E != 0);
	assert(0 == E->Prev);
	assert(Pos == E->Pos);

// Delete from index
	INDEX_ENTRY *NewHead = E->Next;
	if (NewHead == 0)
		{
		Heads[Kmer] = 0;
		Tails[Kmer] = 0;
		}
	else
		{
		assert(NewHead->Prev == E);
		NewHead->Prev = 0;
		}
	Heads[Kmer] = NewHead;

	AddToFreeList(E);
	}

//==============================================================
// End rolling index stuff
//==============================================================

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

// Found a common k-mer
static inline void CommonKmer(int t, int q)
	{
	assert(t >= 0 && t < Tlen - k + 1);
	assert(q >= 0 && q < Qlen - k + 1);

	if (q <= t)
		return;

#if	TRACE
	Log("CommonKmer(%d,%d) SeqQ=%.*s SeqQ=%.*s\n",
	  q, t, k, SeqQ+q, k, SeqQ+t);
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

void FilterB(int Tlen_, char *B_, int Qlen_, const FilterParams &FP, int Diameter,
  bool Comp)
	{
	if (Comp)
		Quit("-diameter requires -fwdonly (this needs to be fixed!)");

	SeqQ = B_;
	Tlen = Tlen_;
	Qlen = Qlen_;

	MinMatch = FP.SeedLength;
	MaxError = FP.SeedDiffs;
	TubeOffset = FP.TubeOffset;

	const int Kmask = pow4(k) - 1;

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

// Initialize index to cover first window
	int StartKmerValidPos = 0;
	int EndKmerValidPos = 0;

	AllocateIndex(Diameter, k);
	const int KmerCount = Diameter - k + 1;

	int Start;
	int End;

	for (Start = 0; Start < KmerCount; ++Start)
		{
		int StartKmer = GetKmer(SeqQ, Start);
		AddToIndex(StartKmer, Start);
		}

#if	DEBUG
	ValidateIndex(SeqQ, 0, Diameter - k);
#endif

// Scan entire sequence.
// Start is coordinate of first base in first k-mer in sliding window
// End is coordinate of first base in last k-mer in sliding window
	Start = 0;
	End = Start + Diameter - k;

	int StartKmer = GetKmer(SeqQ, Start);
	if (StartKmer == -1)
		{
		StartKmer = 0;
		StartKmerValidPos = Start + k + 1;
		}
	int EndKmer = GetKmer(SeqQ, End);
	if (EndKmer == -1)
		{
		EndKmer = 0;
		EndKmerValidPos = End + k + 1;
		}
	for (; End < Qlen - k; ++Start, ++End)
		{
#if	DEBUG
		if (Start%10000 == 0)
			fprintf(stderr, "%d\n", Start);
		//if (Start%1000 == 0)
		//	ValidateIndex(SeqQ, Start, End);
#endif
		if (Start >= StartKmerValidPos)
			{
			assert(StartKmer == GetKmer(SeqQ, Start));
			for (DeclareListPtr(p) = GetListPtr(StartKmer); NotEndOfList(p); p = GetListNext(p))
				{
				int HitPos = GetListPos(p);
				CommonKmer(Start, HitPos);
				}
			DeleteFirstInstanceFromIndex(StartKmer, Start);
			}

		if (0 == --Ticker)
			{
			TubeEnd(Start);
			Ticker = TubeOffset;
			}

		{
		char c = SeqQ[Start + k];
		int x = CharToLetter[c];
		if (x < 0)
			{
			StartKmer = 0;
			StartKmerValidPos = Start + k + 1;
			}
		else
			StartKmer = ((StartKmer << 2) | x) & Kmask;
		}

		{
		char c = SeqQ[End + k];
		int x = CharToLetter[c];
		if (x < 0)
			{
			EndKmer = 0;
			EndKmerValidPos = End + k + 1;
			}
		else
			EndKmer = ((EndKmer << 2) | x) & Kmask;

		if (End+1 >= EndKmerValidPos)
			{
			assert(EndKmer == GetKmer(SeqQ, End+1));
			AddToIndex(EndKmer, End+1);
			}
		}
		}

#if	DEBUG
	ValidateIndex(SeqQ, Start, Qlen - k);
#endif

// Special case for end of sequence, don't slide the index
// for the last Diameter bases.
	for (; Start < Qlen - k; ++Start)
		{
		{
		char c = SeqQ[Start + k];
		int x = CharToLetter[c];
		if (x < 0)
			{
			StartKmer = 0;
			StartKmerValidPos = Start + k + 1;
			}
		else
			StartKmer = ((StartKmer << 2) | x) & Kmask;
		}

		if (Start >= StartKmerValidPos)
			{
			for (DeclareListPtr(p) = GetListPtr(StartKmer); NotEndOfList(p); p = GetListNext(p))
				{
				int HitPos = GetListPos(p);
				CommonKmer(Start, HitPos);
				}
			}

		if (0 == --Ticker)
			{
			TubeEnd(Start);
			Ticker = TubeOffset;
			}
		}

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
