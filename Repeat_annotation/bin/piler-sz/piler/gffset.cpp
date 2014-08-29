/***
GFFSet is a container class for a set of GFF
records. This is to hide issues to do with
retrieving from a file, efficient memory use
etc. The initial implementation here is
designed for simplicity; by hiding the details
we can improve it later as needed without
a big impact on the calling code.
***/

#include "piler2.h"

#define GFFRecord GFFRecord2

GFFSet::GFFSet()
	{
	m_Recs = 0;
	m_RecordCount = 0;
	m_RecordBufferSize = 0;
	m_GLIX = 0;
	m_IIX = 0;
	}

GFFSet::~GFFSet()
	{
	Free();
	}

void GFFSet::Free()
	{
	for (int i = 0; i < m_RecordCount; ++i)
		FreeGFFStrings(m_Recs[i]);
	freemem(m_Recs);

	delete m_GLIX;
	delete m_IIX;

	m_Recs = 0;
	m_RecordCount = 0;
	m_RecordBufferSize = 0;
	m_GLIX = 0;
	m_IIX = 0;
	}

void GFFSet::FromFile(FILE *f)
	{
	Free();

	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		SaveGFFStrings(Rec);
		Add(Rec);
		}
	}

// Caller's respsonsibility to allocate memory
// for string fields, Add() doesn't make copies.
// SaveGFFStrings() makes copies if needed.
void GFFSet::Add(const GFFRecord &Rec)
	{
	if (m_RecordCount > m_RecordBufferSize)
		Quit("GFFSet::Add, m_RecordCount > m_BufferSize");
	if (m_RecordCount == m_RecordBufferSize)
		{
		m_RecordBufferSize += BUFFER_SIZE_INC;
		reall(m_Recs, GFFRecord, m_RecordBufferSize);
		}
	m_Recs[m_RecordCount++] = Rec;
	}

const GFFRecord &GFFSet::Get(int RecordIndex) const
	{
	if (RecordIndex < 0 || RecordIndex >= m_RecordCount)
		Quit("GFFRecord::Get(%d) out of range %d", RecordIndex, m_RecordCount);
	return m_Recs[RecordIndex];
	}

void GFFSet::MakeGLIX()
	{
	m_GLIX = new GLIX;
	m_GLIX->Init();
	m_GLIX->FromGFFSet(*this);
	}

void GFFSet::MakeIIX()
	{
	const int GlobalLength = m_GLIX->GetGlobalLength();
	m_IIX = new IIX;
	m_IIX->Init(GlobalLength);
	m_IIX->SetGLIX(m_GLIX);

	for (int RecordIndex = 0; RecordIndex < m_RecordCount; ++RecordIndex)
		{
		const GFFRecord &Rec = Get(RecordIndex);
		m_IIX->AddLocal(Rec.SeqName, Rec.Start - 1, Rec.End - 1, RecordIndex);
		}
	}
