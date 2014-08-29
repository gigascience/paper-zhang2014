struct FilterParams
	{
	int WordSize;
	int SeedLength;
	int SeedDiffs;
	int TubeOffset;
	};

struct DPParams
	{
	int MinHitLength;
	double MinId;
	};

struct TubeState
	{
	int qLo;
	int qHi;
	int Count;
	};

struct ContigData
	{
	int From;
	int Length;
	int Index;
	char *Label;
	};

struct FilterHit
	{
	int QFrom;
	int QTo;
	int DiagIndex;
	};

struct Trapezoid
	{
	Trapezoid *next;	// Organized in a list linked on this field
	int top, bot;		// B (query) coords of top and bottom of trapzoidal zone
	int lft, rgt;		// Left and right diagonals of trapzoidal zone
	};

struct DPHit
	{
	int abpos, bbpos;	// Start coordinate of local alignment
	int aepos, bepos;	// End coordinate of local alignment
	int ldiag, hdiag;	// Alignment is between (anti)diagonals ldiag & hdiag
	int score;			// Score of alignment where match = 1, difference = -3
	float error;		// Lower bound on error rate of match
	};

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
