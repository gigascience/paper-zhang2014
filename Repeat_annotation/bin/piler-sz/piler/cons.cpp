#include "piler2.h"

void Cons()
	{
	const char *InputFileName = RequiredValueOpt("cons");
	const char *OutputFileName = RequiredValueOpt("out");
	const char *Label = RequiredValueOpt("label");

	ProgressStart("Reading alignment");
	int SeqLength;
	int SeqCount;
	const char *Seqs = ReadAFA(InputFileName, &SeqLength, &SeqCount);
	ProgressDone();
	
	Progress("%d seqs, length %d", SeqCount, SeqLength);

	char *ConsSeq = all(char, SeqLength+1);
	int ConsSeqLength = 0;

	for (int Col = 0; Col < SeqLength; ++Col)
		{
		static const char Letter[5] = { 'A', 'C', 'G', 'T', '-'};
		int Counts[5];
		memset(Counts, 0, 5*sizeof(unsigned));
		for (int SeqIndex = 0; SeqIndex < SeqCount; ++SeqIndex)
			{
			char c = Seqs[SeqIndex*SeqLength + Col];
			c = toupper(c);
			switch (c)
				{
			case 'a':
			case 'A':
				++(Counts[0]);
				break;
			case 'c':
			case 'C':
				++(Counts[1]);
				break;
			case 'g':
			case 'G':
				++(Counts[2]);
				break;
			case 't':
			case 'T':
				++(Counts[3]);
				break;
			case '-':
				++(Counts[4]);
				break;
				}
			}
		int MaxCount = 0;
		char MaxLetter = 'A';
		for (int i = 0; i < 4; ++i)
			{
			if (Counts[i] > MaxCount)
				{
				MaxLetter = Letter[i];
				MaxCount = Counts[i];
				}
			}
		if (MaxLetter == '-')
			continue;
		ConsSeq[ConsSeqLength++] = MaxLetter;
		}

	FILE *f = OpenStdioFile(OutputFileName, FILEIO_MODE_WriteOnly);
	WriteFasta(f, ConsSeq, ConsSeqLength, Label);
	}
