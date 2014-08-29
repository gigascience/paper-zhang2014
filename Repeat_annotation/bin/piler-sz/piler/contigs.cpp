#include "piler2.h"

const int INSANE_LENGTH = 500000000;

// Arbitrarily chosen prime number
static ContigData *HashTable[HASH_TABLE_SIZE];
static ContigData **ContigMap;
static int SeqLength;

void SetSeqLength(int Length)
	{
	SeqLength = Length;
	}

static ContigData *HashLookup(const char *Label)
	{
	unsigned h = Hash(Label);
	assert(h < HASH_TABLE_SIZE);
	ContigData *p = HashTable[h];
	while (p != 0)
		{
		if (0 == strcmp(Label, p->Label))
			return p;
		p = p->Next;
		}
	return 0;
	}

void LogContigs()
	{
	Log("               Label    Hash         Pos     Length\n");
	Log("--------------------  ------  ---------- ----------\n");
	for (int h = 0; h < HASH_TABLE_SIZE; ++h)
		{
		for (const ContigData *p = HashTable[h]; p != 0; p = p->Next)
			{
			const ContigData &Contig = *p;
			Log("%20.20s  %6d  %10d  %10d",
			  Contig.Label,
			  h,
			  Contig.From,
			  Contig.Length);
			if (Hash(Contig.Label) != h)
				Log(" ** Hash=%d", Hash(Contig.Label));
			Log("\n");
			}
		}
	}

static void AppendContig(const char *Label, int Pos)
	{
	ContigData *Contig = all(ContigData, 1);
	Contig->Label = strsave(Label);
	char *Space = strchr(Contig->Label, ' ');
	if (0 != Space)
		*Space = 0;

	unsigned h = Hash(Label);
	assert(h < HASH_TABLE_SIZE);
	ContigData *p = HashTable[h];
	Contig->Length = Pos + 1;
	Contig->Next = p;
	HashTable[h] = Contig;
	}

void AddContigPos(const char *Label, int Pos)
	{
	ContigData *Contig = HashLookup(Label);
	if (0 == Contig)
		AppendContig(Label, Pos);
	else
		{
		if (Pos > Contig->Length)
			Contig->Length = Pos;
		}
	}

void AddContig(const char *Label, int GlobalPos, int Length)
	{
	ContigData *Contig = all(ContigData, 1);
	Contig->Label = strsave(Label);
	char *Space = strchr(Contig->Label, ' ');
	if (0 != Space)
		*Space = 0;

	unsigned h = Hash(Contig->Label);
	assert(h < HASH_TABLE_SIZE);
	ContigData *p = HashTable[h];
	Contig->From = GlobalPos;
	Contig->Length = Length;
	Contig->Next = p;
	HashTable[h] = Contig;
	}

int GlobalizeContigs()
	{
	int GlobalPos = 0;
	for (int h = 0; h < HASH_TABLE_SIZE; ++h)
		{
		for (ContigData *p = HashTable[h]; p != 0; p = p->Next)
			{
			ContigData &Contig = *p;
			const int Length = p->Length;
			if (Length < 1 || Length >= INSANE_LENGTH)
				Quit("GlobalizeContigs, insane length %d", Length);
			p->From = GlobalPos;
			GlobalPos += Length;

		// Pad up to start of next bin
		// (required for contig map)
			int BinRemainder = GlobalPos%CONTIG_MAP_BIN_SIZE;
			if (BinRemainder > 0)
				GlobalPos += CONTIG_MAP_BIN_SIZE - BinRemainder;
			if (GlobalPos%CONTIG_MAP_BIN_SIZE)
				Quit("Dumb mistake rounding contig");
			}
		}
	SeqLength = GlobalPos;
	return SeqLength;
	}

void MakeContigMap()
	{
	if (SeqLength%CONTIG_MAP_BIN_SIZE)
		Quit("MakeContigMap: expects rounded size");

	const int BinCount = SeqLength/CONTIG_MAP_BIN_SIZE;
	ContigMap = all(ContigData *, BinCount);
	zero(ContigMap, ContigData *, BinCount);

	for (int h = 0; h < HASH_TABLE_SIZE; ++h)
		{
		for (ContigData *p = HashTable[h]; p != 0; p = p->Next)
			{
			ContigData &Contig = *p;
			int From = p->From;
			int To = From + p->Length - 1;

			if (From%CONTIG_MAP_BIN_SIZE)
				Quit("MakeContigMap: expected rounded contig from");

			int BinFrom = From/CONTIG_MAP_BIN_SIZE;
			int BinTo = To/CONTIG_MAP_BIN_SIZE;
			for (int Bin = BinFrom; Bin <= BinTo; ++Bin)
				{
				if (ContigMap[Bin] != 0)
					Quit("MakeContigMap: overlap error");
				ContigMap[Bin] = p;
				}
			}
		}
	}

const char *GlobalToContig(int GlobalPos, int *ptrContigPos)
	{
	if (GlobalPos < 0 || GlobalPos >= SeqLength)
		Quit("GlobalToContig: invalid pos");

	const int Bin = GlobalPos/CONTIG_MAP_BIN_SIZE;
	ContigData *Contig = ContigMap[Bin];
	if (0 == Contig)
		Quit("GlobalToContig: doesn't map");
	int ContigPos = GlobalPos - Contig->From;
	if (ContigPos < 0 || ContigPos >= Contig->Length)
		Quit("GlobalToContig: out of bounds");
	*ptrContigPos = ContigPos;
	return Contig->Label;
	}

int ContigToGlobal(int ContigPos, const char *Label)
	{
	const ContigData *Contig = HashLookup(Label);
	if (0 == Contig)
		Quit("ContigToGlobal: contig not found (%s)", Label);
	if (ContigPos < 0 || ContigPos >= Contig->Length)
		Quit("ContigToGlobal: out of bounds");
	return Contig->From + ContigPos;
	}
