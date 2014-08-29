/***
GLIX = Global Local IndeX

This index provides an efficient mapping of a
set of sequences to and from a single set of 
global coordinates such that each sequence has
a unique range of positions. Global coordinates
are convenient in a number of algorithms, and
there may be quite large numbers of sequences
(e.g., contigs or scaffolds in an early assembly),
so efficiency is useful here.

"Local" coordinate is (Label, SeqPos), where
SeqPos is 0-based, i.e. is 0, 1 ... (SeqLength-1)
for each sequence.

"Global" coordindate is GlobalPos, where
GlobalPos = 0, 1 ... (GlobalLength - 1).

To convert from Local to Global, a hash table
is used to look up by sequence name.

To convert from Global to Local, the global
sequence is divided into blocks of length B.
A vector of length GlobalLength/B contains
the sequence index for each block. Padding
is therefore required to ensure that there
are no blocks that map to two different
sequences.
***/

#include "piler2.h"

#define GFFRecord GFFRecord2

GLIX::GLIX()
	{
	m_SeqCount = 0;
	m_GlobalLength = 0;
	m_HashTableSize = 0;
	m_Pad = 0;
	m_HashTable = 0;
	m_SeqMap = 0;
	}

GLIX::~GLIX()
	{
	}

void GLIX::Free()
	{
	// TODO@@
	}

void GLIX::Init(int Pad, int HashTableSize)
	{
	Free();

	m_Pad = Pad;
	m_HashTableSize = HashTableSize;
	m_HashTable = all(SEQDATA *, HashTableSize);
	zero(m_HashTable, SEQDATA *, HashTableSize);
	}

SEQDATA *GLIX::SeqIndexLookup(const char *Label) const
	{
	int h = Hash(Label, m_HashTableSize);
	assert(h >= 0 && h < m_HashTableSize);
	for (SEQDATA *i = m_HashTable[h]; i; i = i->Next)
		if (0 == strcmp(i->Label, Label))
			return i;
	return 0;
	}

SEQDATA *GLIX::AddToIndex(const char *Label, int Length)
	{
	int h = Hash(Label, m_HashTableSize);
	assert(h >= 0 && h < m_HashTableSize);

	SEQDATA *i = all(SEQDATA, 1);
	i->Label = strsave(Label);
	i->Length = Length;
	i->Next = m_HashTable[h];
	m_HashTable[h] = i;
	++m_SeqCount;
	return i;
	}

void GLIX::AssignOffsets()
	{
	int Offset = 0;
	for (int h = 0; h < m_HashTableSize; ++h)
		{
		for (SEQDATA *i = m_HashTable[h]; i; i = i->Next)
			{
			i->Offset = Offset;
			Offset += i->Length;
			const int NewOffset = RoundUp(Offset, m_Pad, SEQMAP_BLOCKSIZE);
			i->RoundedLength = i->Length + NewOffset - Offset;
			Offset = NewOffset;
			}
		}
	m_GlobalLength = Offset;
	}

// Add() is typically used when creating a GLIX from GFF records.
// It can be called multiple times with the same label, the
// maximum position determines the sequence length.
void GLIX::Add(const char *Label, int Pos)
	{
	SEQDATA *IE = SeqIndexLookup(Label);
	if (0 == IE)
		AddToIndex(Label, Pos + 1);
	else
		{
		if (Pos + 1 > IE->Length)
			IE->Length = Pos + 1;
		}
	}

// Insert() is typically used when creating a GLIX from
// a sequence file. It must be called exactly once per label.
void GLIX::Insert(const char *Label, int Offset, int Length)
	{
	const SEQDATA *IE = SeqIndexLookup(Label);
	if (0 != IE)
		Quit("Duplicate sequence label %s", Label);

	int h = Hash(Label, m_HashTableSize);
	assert(h >= 0 && h < m_HashTableSize);

	SEQDATA *i = all(SEQDATA, 1);
	i->Label = strsave(Label);
	i->Length = Length;
	i->Offset = Offset;
	i->Next = m_HashTable[h];
	m_HashTable[h] = i;
	++m_SeqCount;
	}

int GLIX::FromGFFFile(FILE *f)
	{
	int RecordCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		++RecordCount;
		Add(Rec.SeqName, Rec.End - 1);
		if (HasTargetAttrs(Rec.Attrs))
			{
			char TargetName[MAX_GFF_FEATURE_LENGTH+1];
			int Start;
			int End;
			ParseTargetAttrs(Rec.Attrs, TargetName, sizeof(TargetName), &Start, &End);
			Add(TargetName, End - 1);
			}
		}
	AssignOffsets();
	return RecordCount;
	}

int GLIX::FromGFFSet(const GFFSet &Set)
	{
	const int RecordCount = Set.GetRecordCount();
	for (int i = 0; i < RecordCount; ++i)
		{
		const GFFRecord &Rec = Set.Get(i);
		Add(Rec.SeqName, Rec.End - 1);
		}
	AssignOffsets();
	return RecordCount;
	}

void GLIX::LogMe() const
	{
	Log("m_SeqCount=%d\n", m_SeqCount);
	Log("               Label      Length     Hash\n");
	Log("--------------------  ----------  -------\n");
	int Count = 0;
	for (int h = 0; h < m_HashTableSize; ++h)
		{
		for (SEQDATA *i = m_HashTable[h]; i; i = i->Next)
			{
			Log("%20.20s  %10d  %7d\n", i->Label, i->Length, h);
			++Count;
			}
		}
	if (Count != m_SeqCount)
		Log("\n**** ERROR ****   Count=%d\n", Count);
	}

int GLIX::GetGlobalLength() const
	{
	return m_GlobalLength;
	}

int GLIX::GetSeqCount() const
	{
	return m_SeqCount;
	}

int GLIX::GetSeqOffset(const char *Label) const
	{
	const SEQDATA *IE = SeqIndexLookup(Label);
	if (0 == IE)
		Quit("Label not found %s", Label);
	return IE->Offset;
	}

int GLIX::GetSeqLength(const char *Label) const
	{
	const SEQDATA *IE = SeqIndexLookup(Label);
	if (0 == IE)
		Quit("Label not found %s", Label);
	return IE->Length;
	}

void GLIX::MakeGlobalToLocalIndex()
	{
	if (m_GlobalLength%SEQMAP_BLOCKSIZE)
		Quit("MakeGlobalToLocalIndex: expects rounded size");

	const int BinCount = (m_GlobalLength + SEQMAP_BLOCKSIZE - 1)/SEQMAP_BLOCKSIZE;
	m_SeqMap = all(SEQDATA *, BinCount);
	zero(m_SeqMap, SEQDATA *, BinCount);

	for (int h = 0; h < m_HashTableSize; ++h)
		{
		for (SEQDATA *p = m_HashTable[h]; p != 0; p = p->Next)
			{
			SEQDATA &IE = *p;
			int From = p->Offset;
			int To = From + p->Length - 1;

			if (From%SEQMAP_BLOCKSIZE)
				Quit("MakeGlobalToLocalIndex: expected rounded contig from");

			int BinFrom = From/SEQMAP_BLOCKSIZE;
			int BinTo = To/SEQMAP_BLOCKSIZE;
			for (int Bin = BinFrom; Bin <= BinTo; ++Bin)
				{
				if (m_SeqMap[Bin] != 0)
					Quit("MakeGlobalToLocalIndex: overlap error");
				m_SeqMap[Bin] = p;
				}
			}
		}
	}

const char *GLIX::GlobalToSeq(int GlobalPos, int *ptrSeqPos) const
	{
	if (GlobalPos < 0 || GlobalPos >= m_GlobalLength)
		Quit("GlobalToSeqPos: invalid pos");
	if (0 == m_SeqMap)
		Quit("GLIX::MakeGlobalToLocalIndex not called");

	const int Bin = GlobalPos/SEQMAP_BLOCKSIZE;
	SEQDATA *IE = m_SeqMap[Bin];
	if (0 == IE)
		Quit("GlobalToSeqPos: doesn't map");
	int SeqPos = GlobalPos - IE->Offset;
	if (SeqPos < 0 || SeqPos >= IE->Length)
		Quit("GlobalToSeqPos: out of bounds");
	*ptrSeqPos = SeqPos;
	return IE->Label;
	}

const char *GLIX::GlobalToSeqPadded(int GlobalPos, int *ptrSeqPos) const
	{
	if (GlobalPos < 0 || GlobalPos >= m_GlobalLength)
		Quit("GlobalToSeqPos: invalid pos");
	if (0 == m_SeqMap)
		Quit("GLIX::MakeGlobalToLocalIndex not called");

	const int Bin = GlobalPos/SEQMAP_BLOCKSIZE;
	SEQDATA *IE = m_SeqMap[Bin];
	if (0 == IE)
		Quit("GlobalToSeqPos: doesn't map");
	int SeqPos = GlobalPos - IE->Offset;
	if (SeqPos < 0 || SeqPos >= IE->RoundedLength)
		Quit("GlobalToSeqPos: out of bounds");
	*ptrSeqPos = SeqPos;
	return IE->Label;
	}

int GLIX::LocalToGlobal(const char *Label, int LocalPos) const
	{
	const SEQDATA *IE = SeqIndexLookup(Label);
	if (0 == IE)
		Quit("ContigToGlobal: contig not found (%s)", Label);
	if (LocalPos < 0 || LocalPos >= IE->Length)
		Quit("ContigToGlobal: out of bounds");
	return IE->Offset + LocalPos;
	}

int GLIX::LocalToGlobalNoFail(const char *Label, int LocalPos) const
	{
	const SEQDATA *IE = SeqIndexLookup(Label);
	if (0 == IE)
		return -1;
	if (LocalPos < 0 || LocalPos >= IE->Length)
		return -1;
	return IE->Offset + LocalPos;
	}
