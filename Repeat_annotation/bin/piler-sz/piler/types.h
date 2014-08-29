#include <list>
#include <vector>
using namespace std;

enum FILEIO_MODE
	{
	FILEIO_MODE_Undefined = 0,
	FILEIO_MODE_ReadOnly,
	FILEIO_MODE_ReadWrite,
	FILEIO_MODE_WriteOnly
	};

#if	FILEIO_BINARY_MODE
#define FILIO_STRMODE_ReadOnly		"rb"
#define FILIO_STRMODE_WriteOnly		"wb"
#define FILIO_STRMODE_ReadWrite		"w+b"
#else
#define FILIO_STRMODE_ReadOnly		"r"
#define FILIO_STRMODE_WriteOnly		"w"
#define FILIO_STRMODE_ReadWrite		"w+"
#endif

struct HitData
	{
	int QueryFrom;
	int QueryTo;
	int TargetFrom;
	int TargetTo;
	bool Rev;
	};

typedef int PILE_INDEX_TYPE;
const PILE_INDEX_TYPE MAX_STACK_INDEX = 0x7ffffff0;
struct PileImageData
	{
// Hack to enforce structure packing
// in a compiler-independent way
	PILE_INDEX_TYPE Data[3];
#define SILength	Data[0]
#define SIPile		Data[1]
#define SIRev		Data[2]
	};

struct EdgeData
	{
	int Node1;
	int Node2;
	bool Rev;
	};
typedef list<EdgeData> EdgeList;
typedef EdgeList::iterator PtrEdgeList;

struct FamMemberData
	{
	int PileIndex;
	bool Rev;
	};
typedef list<FamMemberData> FamData;
typedef FamData::iterator PtrFamData;

typedef list<FamData *> FamList;
typedef FamList::iterator PtrFamList;

typedef list<int> IntList;
typedef IntList::iterator PtrIntList;

typedef list<IntList *> ListOfIntListPtrs;
typedef ListOfIntListPtrs::iterator PtrListOfIntListPtrs;

struct TRSData
	{
	char *ContigLabel;
	int ContigFrom;
	int ContigTo;
	int FamIndex;
	int SuperFamIndex;
	bool Rev;
	};

struct MotifData
	{
	char *ContigLabel;
	int ContigFrom;
	int ContigTo;
	int FamIndex;
	};

struct PileData
	{
	int From;
	int To;
	int ImageCount;
	PileImageData *Images;
	int SuperFamIndex;
	int FamIndex;
	int Rev;
	};

struct ContigData
	{
	int From;
	int Length;
	char *Label;
	ContigData *Next;
	};

struct GFFRecord
	{
	char SeqName[MAX_GFF_FEATURE_LENGTH+1];
	char Source[MAX_GFF_FEATURE_LENGTH+1];
	char Feature[MAX_GFF_FEATURE_LENGTH+1];
	int Start;
	int End;
	float Score;
	char Strand;
	int Frame;
	char Attrs[MAX_GFF_FEATURE_LENGTH+1];
	};

struct GFFRecord2
	{
	const char *SeqName;
	const char *Source;
	const char *Feature;
	int Start;
	int End;
	float Score;
	char Strand;
	int Frame;
	const char *Attrs;
	};

struct RepData
	{
	char *ContigLabel;
	int ContigFrom;
	int ContigTo;
	char *RepeatName;
	char *RepeatClass;
	int RepeatFrom;
	int RepeatTo;
	int RepeatLeft;
	bool Rev;
	};

class GFFSet;
class GLIX;
class IIX;

#include "gffset.h"
#include "glix.h"
#include "iix.h"
