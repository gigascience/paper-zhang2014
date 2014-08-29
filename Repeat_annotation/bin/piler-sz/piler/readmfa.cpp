#include "piler2.h"

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

char *ReadMFA(FILE *f, int *ptrLength)
	{
	rewind(f);
	int FileSize = GetFileSize(f);
	int BufferSize = FileSize;
	char *Buffer = all(char, BufferSize);

	char prev_c = '\n';
	bool InLabel = false;
	int ContigFrom = 0;
	char *Label = 0;
	int LabelLength = 0;
	int LabelBufferLength = 0;
	int Pos = 0;
	int ContigStart = 0;

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
				Label[LabelLength] = 0;
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
				int ContigLength = Pos - ContigStart;
				if (ContigLength > 0)
					AddContig(Label, ContigStart, ContigLength);

				ContigStart = Pos;
				InLabel = true;
				LabelLength = 0;
				}
			else if (!isspace(c))
				{
				APPEND_CHAR(c)
				}
			}
		prev_c = c;
		}

	int ContigLength = Pos - ContigStart;
	if (ContigLength > 0)
		AddContig(Label, ContigStart, ContigLength);

	*ptrLength = Pos;
	SetSeqLength(Pos);
	return Buffer;
	}

char *ReadMFA(const char FileName[], int *ptrSeqLength)
	{
	FILE *f = OpenStdioFile(FileName);
	char *Seq = ReadMFA(f, ptrSeqLength);
	fclose(f);
	return Seq;
	}
