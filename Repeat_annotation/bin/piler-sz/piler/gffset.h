#define GFFRecord	GFFRecord2

const int BUFFER_SIZE_INC = 4096;

class GFFSet
	{
public:
	GFFSet();
	virtual ~GFFSet();
	void Free();
	
	void FromFile(FILE *f);
	void Add(const GFFRecord &Rec);

	void MakeGLIX();
	void MakeIIX();

	GLIX *GetGLIX() const { return m_GLIX; }
	IIX *GetIIX() const { return m_IIX; }

	const GFFRecord &Get(int RecordIndex) const;
	int GetRecordCount() const { return m_RecordCount; }

private:
	GFFRecord *m_Recs;
	int m_RecordCount;
	int m_RecordBufferSize;
	GLIX *m_GLIX;
	IIX *m_IIX;
	};

#undef GFFRecord
