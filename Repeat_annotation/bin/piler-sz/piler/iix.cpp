/***
IIX = Interval IndeX.

Given a fixed set of intervals on a 
sequence of length L, provides an efficient
way to retrieve all intervals in the set that
have non-zero overlap with given interval.

This implementation is designed to be simple
to implement and efficient for the typical
sets of intervals that I will be dealing
with -- this is not a good general solution
to the problem. The main assumption is that
there are few long intervals.

The sequence is divided into blocks of length B.
For each block, there is a list of intervals
that overlap that block. So an indexed interval
(ii) of length > B will appear in more than one
list, and in fact any ii of length > 1 may appear
in more than one list if it happens to cross
a block boundary. Intervals of length >> B are a
problem because they will appear in many lists,
but for my purposes they are rare.

Each interval is associated with a user-defined
integer. This can be used by the calling code to
map an ii to some data, e.g. a GFF record. How
this is done is up to the caller.
***/

#include "piler2.h"

IIX::IIX()
	{
	m_GlobalLength = 0;
	m_BlockLength = 0;
	m_BlockCount = 0;
	m_Blocks = 0;
	m_GLIX = 0;
	}

IIX::~IIX()
	{
	Free();
	}

void IIX::Free()
	{
	// TODO@@
	m_GlobalLength = 0;
	}

int IIX::PosToBlockIndex(int Pos) const
	{
	return Pos/m_BlockLength;
	}

void IIX::Init(int GlobalLength, int BlockLength)
	{
	m_GlobalLength = GlobalLength;
	m_BlockLength = BlockLength;
	m_BlockCount = (GlobalLength + BlockLength - 1)/BlockLength;
	m_Blocks = all(INTERVAL *, m_BlockCount);
	zero(m_Blocks, INTERVAL *, m_BlockCount);
	m_GLIX = 0;
	}

bool IIX::ValidInterval(int From, int To) const
	{
	if (From < 0 || From >= m_GlobalLength)
		return false;
	if (To < 0 || To >= m_GlobalLength)
		return false;
	if (From > To)
		return false;
	return true;
	}

void IIX::AddGlobal(int GlobalFrom, int GlobalTo, int User)
	{
	assert(ValidInterval(GlobalFrom, GlobalTo));

	const int BlockFrom = PosToBlockIndex(GlobalFrom);
	const int BlockTo = PosToBlockIndex(GlobalTo);
	for (int BlockIndex = BlockFrom; BlockIndex <= BlockTo; ++BlockIndex)
		{
		INTERVAL *ii = all(INTERVAL, 1);

		ii->From = GlobalFrom;
		ii->To = GlobalTo;
		ii->User = User;
		ii->Next = m_Blocks[BlockIndex];

		m_Blocks[BlockIndex] = ii;
		}
	}

void IIX::AddLocal(const char *Label, int LocalFrom, int LocalTo, int User)
	{
	if (0 == m_GLIX)
		Quit("IIX::AddLocal: no GLIX");

	int GlobalFrom = m_GLIX->LocalToGlobal(Label, LocalFrom);
	int GlobalTo = GlobalFrom + (LocalTo - LocalFrom + 1);
	return AddGlobal(GlobalFrom, GlobalTo, User);
	}

int IIX::LookupGlobal(int GlobalFrom, int GlobalTo, int **ptrHits) const
	{
	*ptrHits = 0;
	if (!ValidInterval(GlobalFrom, GlobalTo))
		return 0;

	int *Hits = 0;
	int HitCount = 0;
	int HitBufferSize = 0;
	const int BlockFrom = PosToBlockIndex(GlobalFrom);
	const int BlockTo = PosToBlockIndex(GlobalTo);
	for (int BlockIndex = BlockFrom; BlockIndex <= BlockTo; ++BlockIndex)
		{
		for (INTERVAL *ii = m_Blocks[BlockIndex]; ii; ii = ii->Next)
			{
			if (Overlap(GlobalFrom, GlobalTo, ii->From, ii->To) > 0)
				{
				if (HitCount >= HitBufferSize)
					{
					HitBufferSize += 128;
					reall(Hits, int, HitBufferSize);
					}
				Hits[HitCount++] = ii->User;
				}
			}
		}
	*ptrHits = Hits;
	return HitCount;
	}

int IIX::LookupLocal(const char *Label, int LocalFrom, int LocalTo, int **ptrHits) const
	{
	int GlobalFrom = m_GLIX->LocalToGlobalNoFail(Label, LocalFrom);
	if (-1 == GlobalFrom)
		return 0;

	int GlobalTo = GlobalFrom + (LocalTo - LocalFrom + 1);
	return LookupGlobal(GlobalFrom, GlobalTo, ptrHits);
	}

void IIX::LogMe() const
	{
	Log("IIX %d blocks\n", m_BlockCount);
	Log(" Block        From          To        User\n");
	Log("======  ==========  ==========  ==========\n");
	for (int BlockIndex = 0; BlockIndex < m_BlockCount; ++BlockIndex)
		{
		for (INTERVAL *ii = m_Blocks[BlockIndex]; ii; ii = ii->Next)
			Log("%6d  %10d  %10d  %10d\n",
			  BlockIndex, ii->From, ii->To, ii->User);
		}
	}
