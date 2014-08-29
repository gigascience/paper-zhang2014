#include "piler2.h"

char *strsave(const char *s)
	{
	if (0 == s)
		return 0;
	char *ptrCopy = strdup(s);
	if (0 == ptrCopy)
		Quit("Out of memory");
	return ptrCopy;
	}

static char *StdioStrMode(FILEIO_MODE Mode)
	{
	switch (Mode)
		{
	case FILEIO_MODE_ReadOnly:
		return FILIO_STRMODE_ReadOnly;
	case FILEIO_MODE_WriteOnly:
		return FILIO_STRMODE_WriteOnly;
	case FILEIO_MODE_ReadWrite:
		return FILIO_STRMODE_ReadWrite;
		}
	Quit("StdioStrMode: Invalid mode");
	return "r";
	}

FILE *OpenStdioFile(const char *FileName, FILEIO_MODE Mode)
	{
	char *strMode = StdioStrMode(Mode);
	FILE *f = fopen(FileName, strMode);
	if (0 == f)
		Quit("Cannot open %s, %s [%d]", FileName, strerror(errno), errno);
	return f;
	}

void Rewind(FILE *f)
	{
	int Ok = fseek(f, 0, SEEK_SET);
	if (Ok != 0)
		Quit("Rewind fseek() != 0 errno=%d", errno);

	long CurrPos = ftell(f);
	if (CurrPos != 0)
		Quit("FileSize: ftell=%ld errno=%d", CurrPos, errno);
	}

int GetFileSize(FILE *f)
	{
	long CurrPos = ftell(f);
	if (CurrPos < 0)
		Quit("FileSize: ftell<0 (CurrPos), errno=%d", errno);

	int Ok = fseek(f, 0, SEEK_END);
	if (Ok != 0)
		Quit("FileSize fseek(END) != 0 errno=%d", errno);

	long Size = ftell(f);
	if (Size < 0)
		Quit("FileSize: ftell<0 (size), errno=%d", errno);

	Ok = fseek(f, CurrPos, SEEK_SET);
	if (Ok != 0)
		Quit("FileSize fseek(restore curr pos) != 0 errno=%d", errno);

	long NewPos = ftell(f);
	if (CurrPos < 0)
		Quit("FileSize: ftell=%ld != CurrPos=%ld", CurrPos, NewPos);

	return (int) Size;
	}

int Overlap(int From1, int To1, int From2, int To2)
	{
	return min(To1, To2) - max(From1, From2);
	}

// Add minimum possible value of j to i such that:
//	(a) j >= MinInc, and
//	(b) (i + j)%MultipleOf = 0.
int RoundUp(int i, int MinInc, int MultipleOf)
	{
	int newi = i + MinInc;
	int k = newi%MultipleOf;
	if (k > 0)
		newi += (MultipleOf - k);
	assert(newi >= i + MinInc && 0 == newi%MultipleOf);
	return newi;
	}
