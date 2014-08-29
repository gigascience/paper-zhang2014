#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include <stdarg.h>

#define PALS_LONG_VERSION	"PALS v1.0"

#if	_MSC_VER
#pragma warning(disable:4800)	// don't warn about bool->int conversion
#endif

#ifdef _DEBUG
#define DEBUG	1
#endif

#ifdef	WIN32
#define FILEIO_BINARY_MODE	1
#else
#define FILEIO_BINARY_MODE	0
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif

#include "types.h"

const int CONTIG_MAP_BIN_SIZE = 1024;

extern int k;
extern int CharToLetter[256];

char *strsave(const char *str);
int pow4(int n);
double pow4d(int n);
double log4(double x);

void Quit(const char *Format, ...);
void Warning(const char *Format, ...);
void Log(const char *Format, ...);
void ProgressStart(const char *Format, ...);
void Progress(const char *Format, ...);
void ProgressDone();
void SetLog();
void Usage();
void Credits();
int GetElapsedSecs();

FILE *OpenStdioFile(const char *FileName, FILEIO_MODE Mode = FILEIO_MODE_ReadOnly);
int GetFileSize(FILE *f);

void ProcessArgVect(int argc, char *argv[]);
const char *ValueOpt(const char *Name);
const char *RequiredValueOpt(const char *Name);
bool FlagOpt(const char *Name);
void CommandLineError(const char *Format, ...);

char *ReadMFA(const char FileName[], int *ptrLength, ContigData **ptrContigs,
  int *ptrContigCount, int **ptrContigMap);
int *MakeContigMap(const ContigData *Contigs, int ContigCount);
void Complement(char *seq, int len);
void LogContigs(const ContigData *Contigs, int ContigCount);

double GetRAMSize();

int MinWordsPerFilterHit(int HitLength, int WordLength, int MaxErrors);
void GetParams(int SeqLengthT, int SeqLengthQ, bool Self,
  FilterParams *ptrFP, DPParams *ptrDP);
double TotalMemRequired(int SeqLengthT, int SeqLengthQ, bool Self,
  const FilterParams &FP);
double AvgIndexListLength(int SeqLengthT, const FilterParams &FP);

void SaveFilterHit(int QFrom, int QTo, int DiagIndex);
void WriteDPHits(FILE *f, const DPHit *DPHits, int DPHitCount, bool Comp);
void SetContigs(ContigData *ContigsT, ContigData *ContigsQ,
  int ContigCountT, int ContigCountQ, int *ContigMapT, int *ContigMapQ);
int GetFilterHitCount();
int GetFilterHitCountComp();

void Filter(int Tlen_, char *B_, int Qlen_, bool Self, bool Comp,
  const int *Finger, const int *Pos, const FilterParams &FP);
void FilterB(int Tlen_, char *B_, int Qlen_,
  const FilterParams &FP, int Diameter, bool Comp);
void SetFilterOutFile(FILE *f);
void SetFilterOutFileComp(FILE *f);
FilterHit *ReadFilterHits(FILE *f, int Count);
void CloseFilterOutFile();
void CloseFilterOutFileComp();

Trapezoid *MergeFilterHits(const char *SeqT, int SeqLengthT, const char *SeqQ,
  int SeqLengthQ,  bool Self, const FilterHit *FilterHits,
  int FilterHitCount, const FilterParams &FP, int *ptrTrapCount);

DPHit *AlignTraps(char *A, int Alen, char *B, int Blen, Trapezoid *Traps,
  int TrapCount, int comp, const DPParams &DP, int *ptrSegCount);
int SumTrapLengths(const Trapezoid *Traps);
int SumDPLengths(const DPHit *Hits, int HitCount);

int StringToCode(const char s[], int len);
char *CodeToString(int code, int len);

void MakeIndex(char *S, int Slen, int **ptrFinger, int **ptrPos);
void CheckIndex(char *S, int Slen, const int Finger[], const int Pos[]);
void FreeIndex(int Finger[], int Pos[]);

// Memory wrappers.
// Macro hacks, but makes code more readable
// by hiding cast and sizeof.
#define	all(t, n)		(t *) allocmem((n)*sizeof(t))
#define zero(p,	t, n)	memset(p, 0, (n)*sizeof(t))
void *allocmem(int bytes);
void freemem(void *p);
unsigned GetPeakMemUseBytes();
unsigned GetMemUseBytes();

void *ckalloc(int size, char *where);
void *ckrealloc(void *p, int size, char *where);

void PALS();
