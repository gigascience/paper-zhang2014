const int DEFAULT_BLOCK_LENGTH = 10000;

// From and To are 0-based coordinates,
// i.e. are >= 0 and < m_GlobalLength.
struct INTERVAL
	{
	int From;
	int To;
	int User;
	INTERVAL *Next;
	};

class IIX
	{
public:
	IIX();
	virtual ~IIX();

	void Init(int GlobalLength, int BlockLength = DEFAULT_BLOCK_LENGTH);
	void SetGLIX(GLIX *ptrGLIX) { m_GLIX = ptrGLIX; }

	void Free();
	void AddGlobal(int GlobalFrom, int GlobalTo, int User);
	void AddLocal(const char *Label, int LocalFrom, int LocalTo, int User);

	int LookupGlobal(int GlobalFrom, int GlobalTo, int **ptrHits) const;
	int LookupLocal(const char *Label, int LocalFrom, int LocalTo, int **ptrHits) const;

	bool ValidInterval(int From, int To) const;

	void LogMe() const;

private:
	int PosToBlockIndex(int Pos) const;

private:
	int m_GlobalLength;
	int m_BlockLength;
	int m_BlockCount;
	INTERVAL **m_Blocks;
	GLIX *m_GLIX;
	};
