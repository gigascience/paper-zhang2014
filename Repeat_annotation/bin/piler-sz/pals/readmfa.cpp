#include "pals.h"

const int DP_PAD = 50;	// padding to stop alignments
static bool g_TruncateLabels = true;

#define APPEND_CHAR(c)							\
	{											\
	if (Pos >= BufferSize)						\
		Quit("ReadMFA: buffer too small");		\
	Buffer[Pos++] = (c);						\
	}

#define APPEND_LABEL(c)							\
	{											\
	if (LabelLength >= LabelBufferLength-1)		\
		{										\
		LabelBufferLength += 128;				\
		char *NewLabel = all(char, LabelBufferLength); \
		memcpy(NewLabel, Label, LabelLength);	\
		freemem(Label);							\
		Label = NewLabel;						\
		}										\
	Label[LabelLength] = c;						\
	++LabelLength;								\
	}

#define INIT_CONTIGS()							\
	{											\
	ContigBufferCount = 128;					\
	Contigs = all(ContigData, ContigBufferCount);	\
	ContigCount = 0;							\
	}

#define APPEND_CONTIG()							\
	{											\
	if (ContigCount >= ContigBufferCount)		\
		{										\
		ContigBufferCount += 128;				\
		ContigData *NewContigs = all(ContigData, ContigBufferCount); \
		memcpy(NewContigs, Contigs, ContigCount*sizeof(ContigData)); \
		freemem(Contigs);						\
		Contigs = NewContigs;					\
		}										\
	++ContigCount;								\
	}

void LogContigs(const ContigData *Contigs, int ContigCount)
	{
	Log(" Index                 Label         From       Length\n");
	Log("------  --------------------  -----------  -----------\n");
	for (int i = 0; i < ContigCount; ++i)
		{
		const ContigData *ptrContig = Contigs + i;
		Log("%6d  %20.20s  %11d  %11d",
		  ptrContig->Index,
		  ptrContig->Label,
		  ptrContig->From,
		  ptrContig->Length);
		if (ptrContig->From%CONTIG_MAP_BIN_SIZE)
			Log("  Bin %d Remainder %d",
			  ptrContig->From/CONTIG_MAP_BIN_SIZE,
			  ptrContig->From%CONTIG_MAP_BIN_SIZE);
		Log("\n");
		}
	}

char *ReadMFA(FILE *f, int *ptrLength, ContigData **ptrContigs, int *ptrContigCount)
	{
	rewind(f);
	int FileSize = GetFileSize(f);
	int BufferSize = FileSize + 10000*CONTIG_MAP_BIN_SIZE;
	char *Buffer = all(char, BufferSize);

	char prev_c = '\n';
	bool InLabel = false;
	int ContigFrom = 0;
	char *Label = 0;
	int LabelLength = 0;
	int LabelBufferLength = 0;
	int Pos = 0;
	int PrevContigTo = -1;
	int ContigBufferCount = 0;
	int ContigCount = 0;
	ContigData *Contigs;
	INIT_CONTIGS()

	for (;;)
		{
		int c = fgetc(f);
		if (EOF == c)
			{
			if (feof(f))
				break;
			Quit("Stream error");
			}
		if (InLabel)
			{
			if (c == '\r')
				continue;
			if ('\n' == c)
				{
				APPEND_CONTIG()
				ContigData *ptrContig = Contigs + ContigCount - 1;
				ptrContig->From = ContigFrom;
				ptrContig->Index = ContigCount - 1;

				InLabel = false;
				}
			else
				{
				APPEND_LABEL(c)
				}
			}
		else
			{
			if ('>' == c && '\n' == prev_c)
				{
				InLabel = true;
				if (ContigCount > 0)
					{
					PrevContigTo = Pos - 1;
					ContigData *ptrPrevContig = Contigs + ContigCount - 1;
					ptrPrevContig->Length = PrevContigTo - ptrPrevContig->From + 1;
					Label[LabelLength] = 0;
					if (g_TruncateLabels)
						{
						char *ptrSpace = strchr(Label, ' ');
						if (0 != ptrSpace)
							*ptrSpace = 0;
						}
					ptrPrevContig->Label = strsave(Label);
					LabelLength = 0;
					int BinRemaining = CONTIG_MAP_BIN_SIZE - (PrevContigTo + 1)%CONTIG_MAP_BIN_SIZE;
					int PadLength = BinRemaining;
					if (PadLength < DP_PAD)
						PadLength += CONTIG_MAP_BIN_SIZE;
					for (int i = 0; i < PadLength; ++i)
						{
						APPEND_CHAR('N')
						}
					}
				ContigFrom = Pos;
				if (ContigFrom%CONTIG_MAP_BIN_SIZE != 0)
					Quit("ReadMFA logic error");
				}
			else if (!isspace(c))
				{
				APPEND_CHAR(c)
				}
			}
		prev_c = c;
		}

	if (ContigCount > 0)
		{
		ContigData *ptrPrevContig = Contigs + ContigCount - 1;
		ptrPrevContig->Length = Pos - ptrPrevContig->From;
		Label[LabelLength] = 0;
		if (g_TruncateLabels)
			{
			char *ptrSpace = strchr(Label, ' ');
			if (0 != ptrSpace)
				*ptrSpace = 0;
			}
		ptrPrevContig->Label = strsave(Label);
		}

	*ptrContigs = Contigs;
	*ptrContigCount = ContigCount;
	*ptrLength = Pos;
	return Buffer;
	}

char *ReadMFA(const char FileName[], int *ptrSeqLength, ContigData **ptrContigs,
  int *ptrContigCount, int **ptrContigMap)
	{
	FILE *f = OpenStdioFile(FileName);
	char *Seq = ReadMFA(f, ptrSeqLength, ptrContigs, ptrContigCount);
	*ptrContigMap = MakeContigMap(*ptrContigs, *ptrContigCount);
	fclose(f);
	return Seq;
	}
