#define GFFRecord GFFRecord2

const int SEQMAP_BLOCKSIZE = 1024;
const int DEFAULT_HASH_TABLE_SIZE = 17909;
const int DEFAULT_PAD = 0;

struct SEQDATA
	{
	char *Label;
	int Length;
	int RoundedLength;
	int Offset;
	SEQDATA *Next;
	};

class GLIX
	{
public:
	GLIX();
	virtual ~GLIX();
	void Free();

	void Init(int Pad = DEFAULT_PAD, int HashTableSize = DEFAULT_HASH_TABLE_SIZE);

	const char *GlobalToSeq(int GlobalPos, int *ptrSeqPos) const;
	const char *GlobalToSeqPadded(int GlobalPos, int *ptrSeqPos) const;
	int LocalToGlobal(const char *Label, int LocalPos) const;
	int LocalToGlobalNoFail(const char *Label, int LocalPos) const;

	int FromGFFFile(FILE *f);
	int FromGFFSet(const GFFSet &Set);

	void Add(const char *Label, int LocalPos);
	void Insert(const char *Label, int Offset, int Length);

	void MakeGlobalToLocalIndex();

	int GetGlobalLength() const;
	int GetSeqCount() const;
	int GetSeqOffset(const char *Label) const;
	int GetSeqLength(const char *Label) const;
	void LogMe() const;

private:
	SEQDATA *AddToIndex(const char *Label, int Length);
	void AssignOffsets();

	SEQDATA *SeqIndexLookup(const char *Label) const;

private:
	SEQDATA **m_HashTable;
	SEQDATA **m_SeqMap;

	int m_SeqCount;
	int m_HashTableSize;
	int m_GlobalLength;
	int m_Pad;
	};

#undef	GFFRecord
