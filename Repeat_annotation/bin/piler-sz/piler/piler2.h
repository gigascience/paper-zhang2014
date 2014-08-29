#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <assert.h>
#include <errno.h>
#include <stdarg.h>

#define PILER_LONG_VERSION "PILER v1.0"

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

#include "params.h"
#include "types.h"

extern bool g_Quiet;
extern const char *g_ProcessName;

// Memory wrappers.
// Macro hacks, but makes code more readable
// by hiding cast and sizeof.
#define	all(t, n)		(t *) allocmem((n)*sizeof(t))
#define	reall(p, t, n)		p = (t *) reallocmem(p, (n)*sizeof(t))
#define zero(p,	t, n)	memset(p, 0, (n)*sizeof(t))
void *allocmem(int bytes);
void freemem(void *p);
void *reallocmem(void *p, int bytes);

char *strsave(const char *s);

FILE *OpenStdioFile(const char *FileName, FILEIO_MODE Mode = FILEIO_MODE_ReadOnly);
void Rewind(FILE *f);
int GetFileSize(FILE *f);

// FASTA input / output
// MFA=multi FASTA (>= 1 sequence in file)
// AFA=aligned FASTA (>= 1 sequence with gaps, must be same length)
char *ReadMFA(const char FileName[], int *ptrSeqLength);
char *ReadAFA(const char FileName[], int *ptrSeqLength, int *ptrSeqCount);
void WriteFasta(FILE *f, const char *Seq, int Length, const char *Label, bool Rev = false);

void Usage();
void Quit(const char szFormat[], ...);

void SetLog();
void Log(const char Format[], ...);
void Warning(const char Format[], ...);

void ProgressStart(const char *Format, ...);
void Progress(const char *Format, ...);
void ProgressDone();
int GetElapsedSecs();
unsigned GetMaxMemUseBytes();

void ProcessArgVect(int argc, char *argv[]);
const char *ValueOpt(const char *Name);
const char *RequiredValueOpt(const char *Name);
bool FlagOpt(const char *Name);
void CommandLineError(const char *Format, ...);

unsigned GetPeakMemUseBytes();
unsigned GetMemUseBytes();
double GetRAMSize();

int FindConnectedComponents(EdgeList &Edges, FamList &Fams,
  int MinComponentSize);

void AddContig(const char *Label, int GlobalPos, int Length);
void AddContigPos(const char *Label, int Pos);
void LogContigs();
int GlobalizeContigs();
const char *GlobalToContig(int GlobalPos, int *ptrContigPos);
int ContigToGlobal(int ContigPos, const char *Label);
void MakeContigMap();
void SetSeqLength(int Length);
unsigned Hash(const char *key);
unsigned Hash(const char *key, unsigned TableSize);
int Overlap(int From1, int To1, int From2, int To2);
int RoundUp(int i, int MinInc, int MultipleOf);

static inline int iabs(int i)
	{
	return i > 0 ? i : -i;
	}

const char *MakeAnnot(const char *Label, int Start, int End, bool Rev,
  const RepData *Reps, int RepCount);
const char *MakeAnnotEdge(const char *Label, int SeqFrom, int SeqTo, bool Rev,
  const RepData *Reps, int RepCount);

// GFF helpers
int GetFields(char *Line, char **Fields, int MaxFields, char FS);
bool GetNextGFFRecord(FILE *f, GFFRecord &Rec);
void WriteGFFRecord(FILE *f, const GFFRecord &Rec);
extern int GFFLineNr;

bool GetNextGFFRecord(FILE *f, GFFRecord2 &Rec);
void WriteGFFRecord(FILE *f, const GFFRecord2 &Rec);

void GFFRecordToHit(const GLIX &Glix, const GFFRecord2 &Rec, HitData &Hit);
void HitToGFFRecord(const GLIX &Glix, const HitData &Hit, GFFRecord2 &Rec, char AnnotBuffer[]);
void FreeGFFStrings(GFFRecord2 &Rec);
void SaveGFFStrings(GFFRecord2 &Rec);

bool HasTargetAttrs(const char *Attrs);
void ParseTargetAttrs(const char *Attrs, char SeqName[],
  int SeqNameBytes, int *ptrStart, int *ptrEnd);
void ParsePilesAttrs(const char *Attrs, int *ptrQueryPile, int *ptrTargetPile);

// GFF input
HitData *ReadHits(const char *FileName, int *ptrHitCount, int *ptrSeqLength);
TRSData *ReadTRS(const char *FileName, int *ptrTRSCount);
RepData *ReadReps(const char *FileName, int *ptrRepCount);
MotifData *ReadMotif(const char *FileName, int *ptrMotifCount);

// GFF output
void WriteTRSFile(const char *OutputFileName, const PileData *Piles, int PileCount);
void WritePiles(const char *OutputFileName, const PileData *Piles, int PileCount);
void WriteImages(const char *OutputFileName, const HitData *Hits, int PileCount,
  const PILE_INDEX_TYPE *PileIndexes);

// Commands
void TR();
void TRS();
//void TRS2();
void TRS2Fasta();
void Cons();
void Annot();
void AnnotEdge();
void Tanmotif2Fasta();
void Tan();
