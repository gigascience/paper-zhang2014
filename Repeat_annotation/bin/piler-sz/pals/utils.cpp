#include "pals.h"
#include <math.h>

unsigned char CompChar[256];
int CharToLetter[256];

static void InitCharToLetter()
	{
	for (int i = 0; i < 256; ++i)
		CharToLetter[i] = -1;
	CharToLetter['A'] = 0;
	CharToLetter['a'] = 0;
	CharToLetter['C'] = 1;
	CharToLetter['c'] = 1;
	CharToLetter['G'] = 2;
	CharToLetter['g'] = 2;
	CharToLetter['T'] = 3;
	CharToLetter['t'] = 3;
	}

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

static bool InitUtils()
	{
	InitCompChar();
	InitCharToLetter();
	return true;
	}

static bool UtilsInitialized = InitUtils();

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

// 4^n
int pow4(int n)
	{
	assert(n >= 0 && n < 16);
	return (1 << (2*n));
	}

// 4^d, but much less likely to under or overflow
double pow4d(int n)
	{
	return pow(4, n);
	}

double log4(double x)
	{
	static double LOG4 = log(4);
	return log(x)/LOG4;
	}

// Ukonnen's Lemma
int MinWordsPerFilterHit(int HitLength, int WordLength, int MaxErrors)
	{
	return HitLength + 1 - WordLength*(MaxErrors + 1);
	}

int StringToCode(const char s[], int len)
	{
	int code = 0;
	for (int i = 0; i < len; ++i)
		{
		char c = s[i];
		switch (c)
			{
		case 'a': case 'A':
			code <<= 2;
			code |= 0x00;
			break;
		case 'c': case 'C':
			code <<= 2;
			code |= 0x01;
			break;
		case 'g': case 'G':
			code <<= 2;
			code |= 0x02;
			break;
		case 't': case 'T':
			code <<= 2;
			code |= 0x03;
			break;
		default:
			return -1;
			}
		}
	return code;
	}

char *CodeToString(int code, int len)
	{
	static char Str[100];
	static char Symbol[] = { 'A', 'C', 'G', 'T' };
	int i;

	assert(len < sizeof(Str));
	Str[len] = 0;
	for (i = len-1; i >= 0; --i)
		{
		Str[i] = Symbol[code & 0x3];
		code >>= 2;
		}
	return Str;
	}

void *ckalloc(int size, char *where)
{ void *p;
  p = malloc(size);
  if (p == NULL) Quit("Out of memory (ckalloc)");
  return (p);
}

void *ckrealloc(void *p, int size, char *where)
{ p = realloc(p,size);
  if (p == NULL) Quit("Out of memory (ckrealloc)");
  return (p);
}
