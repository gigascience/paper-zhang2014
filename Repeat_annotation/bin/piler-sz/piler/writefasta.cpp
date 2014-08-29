#include "piler2.h"


unsigned char CompChar[256];

static void InitCompChar()
	{
	for (unsigned i = 0; i < 256; ++i)
		CompChar[i] = (unsigned char) i;

	CompChar['a'] = 't';
	CompChar['c'] = 'g';
	CompChar['g'] = 'c';
	CompChar['t'] = 'a';
	CompChar['n'] = 'n';
	CompChar['A'] = 'T';
	CompChar['C'] = 'G';
	CompChar['G'] = 'C';
	CompChar['T'] = 'A';
	}

void WriteFasta(FILE *f, const char *Seq, int Length, const char *Label, bool Rev)
	{
	static bool CompCharInit = false;
	if (!CompCharInit)
		{
		InitCompChar();
		CompCharInit = true;
		}

	fprintf(f, ">%s\n", Label);

	if (Rev)
		{
		int Index = Length;
		for (int i = 0; i < Length; i += FASTA_BLOCK)
			{
			int n = FASTA_BLOCK;
			if (i + n > Length)
				n = Length - i;
			for (int j = 0; j < n; ++j)
				{
				const unsigned char c = Seq[--Index];
				const unsigned char cComp = CompChar[c];
				fputc(cComp, f);
				}
			fputc('\n', f);
			}
		}
	else
		{
		for (int i = 0; i < Length; i += FASTA_BLOCK)
			{
			int n = FASTA_BLOCK;
			if (i + n > Length)
				n = Length - i;
			for (int j = 0; j < n; ++j)
				fputc(*Seq++, f);
			fputc('\n', f);
			}
		}
	}
