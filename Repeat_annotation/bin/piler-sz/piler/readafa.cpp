#include "piler2.h"

char *ReadAFA(FILE *f, int *ptrSeqLength, int *ptrSeqCount)
	{
	rewind(f);
	int FileSize = GetFileSize(f);
	int BufferSize = FileSize;
	char *Buffer = all(char, BufferSize);

	char prev_c = '\n';
	bool InLabel = false;
	int Pos = 0;
	int SeqStart = 0;
	int SeqCount = 0;
	int SeqLength;

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
				InLabel = false;
			}
		else
			{
			if ('>' == c && '\n' == prev_c)
				{
				int ThisSeqLength = Pos - SeqStart;
				if (0 == SeqCount)
					;
				else if (1 == SeqCount)
					SeqLength = ThisSeqLength;
				else if (SeqCount > 1)
					{
					if (SeqLength != ThisSeqLength)
						Quit("ReadAFA: sequence lengths differ %d %d",
						  SeqLength, ThisSeqLength);
					}
				++SeqCount;
				SeqStart = Pos;
				InLabel = true;
				}
			else if (!isspace(c))
				{
				if (Pos >= BufferSize)
					Quit("ReadAFA: buffer too small");
				Buffer[Pos++] = (c);
				}
			}
		prev_c = c;
		}

	int ThisSeqLength = Pos - SeqStart;
	if (0 == SeqCount)
		SeqLength = ThisSeqLength;
	else
		{
		if (SeqLength != ThisSeqLength)
			Quit("ReadAFA: sequence lengths differ %d %d",
				SeqLength, ThisSeqLength);
		}

	*ptrSeqCount = SeqCount;
	*ptrSeqLength = SeqLength;

	if (Pos != SeqCount*SeqLength)
		Quit("ReadAFA: Internal error");
	return Buffer;
	}

char *ReadAFA(const char FileName[], int *ptrSeqLength, int *ptrSeqCount)
	{
	FILE *f = OpenStdioFile(FileName);
	char *Seqs = ReadAFA(f, ptrSeqLength, ptrSeqCount);
	fclose(f);
	return Seqs;
	}
