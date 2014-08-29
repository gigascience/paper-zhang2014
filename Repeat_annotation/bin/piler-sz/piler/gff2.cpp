#include "piler2.h"

#define GFFRecord GFFRecord2

// GFF fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9

static int GFFLineNr2;

bool HasTargetAttrs(const char *Attrs)
	{
	const char *ptrTarget = strstr(Attrs, "Target ");
	return 0 != ptrTarget;
	}

//  Piles 123 456
//  0123456
void ParsePilesAttrs(const char *Attrs, int *ptrQueryPile, int *ptrTargetPile)
	{
	const char *ptrPiles = strstr(Attrs, "Piles ");
	if (0 == ptrPiles)
		Quit("Piles attribute not found");

	const char *ptrValues = ptrPiles + 6;
	int n = sscanf(ptrValues, "%d %d", ptrQueryPile, ptrTargetPile);
	if (n != 2)
		Quit("ParsePilesAttrs, sscanf(%s)=%d",  ptrValues, n);
	}

//  BandClust 123
//  01234567890
void ParseBandClustAttrs(const char *Attrs, int *ptrBandClustIndex)
	{
	const char *ptrBandClust = strstr(Attrs, "BandClust ");
	if (0 == ptrBandClust)
		Quit("BandClust attribute not found");

	const char *ptrIndex = ptrBandClust + 10;
	*ptrBandClustIndex = atoi(ptrIndex);
	}

//  Pyramid 123
//  01234567890
void ParsePyramidAttrs(const char *Attrs, int *ptrClustIndex)
	{
	const char *p = strstr(Attrs, "Pyramid ");
	if (0 == p)
		Quit("Pyramid attribute not found");

	const char *ptrIndex = p + 8;
	*ptrClustIndex = atoi(ptrIndex);
	}

//  Target SeqName 123 456
//  01234567
void ParseTargetAttrs(const char *Attrs, char SeqName[],
  int SeqNameBytes, int *ptrStart, int *ptrEnd)
	{
	const char *ptrTarget = strstr(Attrs, "Target ");
	if (0 == ptrTarget)
		Quit("Target attribute not found");

	const char *ptrRest = ptrTarget + 7;
	const char *ptrBlank = strchr(ptrRest, ' ');
	if (0 == ptrBlank)
		Quit("Invalid Target attributes '%s', missing blank", Attrs);
	size_t NameLength = ptrBlank - ptrRest;
	if (NameLength >= (size_t) SeqNameBytes)
		Quit("Target name length too long '%s'", Attrs);
	memcpy(SeqName, ptrRest, NameLength);
	SeqName[NameLength] = 0;
	int n = sscanf(ptrBlank+1, "%d %d", ptrStart, ptrEnd);
	if (n != 2)
		Quit("Invalid Target start/end attributes '%s', sscanf=%d", ptrBlank+1);
	}

// Destructive read -- pokes nuls onto FS
static int GetFields2(char *Line, char **Fields, int MaxFields, char FS)
	{
	char *p = Line;
	for (int FieldIndex = 0; FieldIndex < MaxFields; ++FieldIndex)
		{
		Fields[FieldIndex] = p;
		char *Tab = strchr(p, FS);
		char *End = Tab;
		if (0 == End)
			End = strchr(p, '\0');
		size_t FieldLength = End - p;
		if (FieldLength > MAX_GFF_FEATURE_LENGTH)
			Quit("Max GFF field length exceeded, field is %d chars, max=%d, line %d",
			  FieldLength, MAX_GFF_FEATURE_LENGTH, GFFLineNr2);
		if (0 == Tab)
			return FieldIndex + 1;
		*Tab = 0;
		p = Tab + 1;
		}
	return MaxFields;
	}

// WARNING: Line[] and Fields[]are overwritten
// by each call to GetNextGFFRecord.
// The Rec agument to GetNextGFFRecord returns
// pointers into Line[].
static char Line[MAX_GFF_LINE+1];
static char *Fields[9];

bool GetNextGFFRecord(FILE *f, GFFRecord &Rec)
	{
	for (;;)
		{
		++GFFLineNr2;
		const char TAB = '\t';
		char *Ok = fgets(Line, sizeof(Line), f);
		if (NULL == Ok)
			{
			if (feof(f))
				return false;
			Quit("Error reading GFF file, line=%d feof=%d ftell=%d ferror=%d errno=%d",
			  GFFLineNr2, feof(f), ftell(f), ferror(f), errno);
			}
		if ('#' == Line[0])
			continue;
		size_t n = strlen(Line);
		if (0 == n)
			Quit("fgets returned zero-length line");
		if (Line[n-1] != '\n')
			Quit("Max line length in GFF file exceeded, line %d is %d chars long, max=%d",
			  GFFLineNr2, n - 1, MAX_GFF_LINE);
		Line[n-1] = 0;	// delete newline

		int FieldCount = GetFields2(Line, Fields, 9, '\t');
		if (FieldCount < 8)
			Quit("GFF record has < 8 fields, line %d", GFFLineNr2);

		char *SeqName = Fields[0];
		char *Source = Fields[1];
		char *Feature = Fields[2];
		char *Start = Fields[3];
		char *End = Fields[4];
		char *Score = Fields[5];
		char *Strand = Fields[6];
		char *Frame = Fields[7];
		char *Attrs = Fields[8];

	// Truncate attrs if comment found
		char *Pound = strchr(Attrs, '#');
		if (0 != Pound)
			*Pound = 0;

		Rec.SeqName = SeqName;
		Rec.Source = Source;
		Rec.Feature = Feature;
		Rec.Start = atoi(Start);
		Rec.End = atoi(End);
		Rec.Score = (float) atof(Score);
		Rec.Strand = Strand[0];
		Rec.Frame = Frame[0] == '.' ? -1 : atoi(Frame);
		Rec.Attrs = Attrs;

		return true;
		}
	}

// GFF fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9
void WriteGFFRecord(FILE *f, const GFFRecord &Rec)
	{
	fprintf(f, "%s\t%s\t%s\t%d\t%d\t%.3g\t%c",
	//           0   1   2   3   4   5     6   7   8
	  Rec.SeqName,	// 0
	  Rec.Source,	// 1
	  Rec.Feature,	// 2
	  Rec.Start,	// 3
	  Rec.End,		// 4
	  Rec.Score,	// 5
	  Rec.Strand);	// 6

	if (-1 == Rec.Frame)
		fprintf(f, "\t.");
	else
		fprintf(f, "\t%d", Rec.Frame);

	fprintf(f, "\t%s\n", Rec.Attrs);
	}

void SaveGFFStrings(GFFRecord &Rec)
	{
	Rec.SeqName = strsave(Rec.SeqName);
	Rec.Feature = strsave(Rec.Feature);
	Rec.Source = strsave(Rec.Source);
	Rec.Attrs = strsave(Rec.Attrs);
	}

void FreeGFFStrings(GFFRecord &Rec)
	{
	free((void *) Rec.SeqName);
	free((void *) Rec.Feature);
	free((void *) Rec.Source);
	free((void *) Rec.Attrs);

	Rec.SeqName = 0;
	Rec.Feature = 0;
	Rec.Source = 0;
	Rec.Attrs = 0;
	}

void GFFRecordToHit(const GLIX &Glix, const GFFRecord &Rec, HitData &Hit)
	{
	if (0 != strcmp(Rec.Feature, "hit"))
		Quit("GFFRecordToHit: feature=%s", Rec.Feature);

	const int QueryLength = Rec.End - Rec.Start + 1;
	Hit.QueryFrom = Glix.LocalToGlobal(Rec.SeqName, Rec.Start - 1);
	Hit.QueryTo = Hit.QueryFrom + QueryLength - 1;

	char TargetName[MAX_GFF_FEATURE_LENGTH+1];
	int TargetStart;
	int TargetEnd;
	ParseTargetAttrs(Rec.Attrs, TargetName, sizeof(TargetName), &TargetStart, &TargetEnd);

	const int TargetLength = TargetEnd - TargetStart + 1;
	Hit.TargetFrom = Glix.LocalToGlobal(TargetName, TargetStart - 1);
	Hit.TargetTo = Hit.TargetFrom + TargetLength - 1;

	Hit.Rev = (Rec.Strand == '-');
	}

void HitToGFFRecord(const GLIX &Glix, const HitData &Hit, GFFRecord &Rec, char AnnotBuffer[])
	{
	Rec.Source = "piler";
	Rec.Feature = "hit";
	Rec.Score = 0;
	Rec.Frame = '.';
	Rec.Strand = (Hit.Rev ? '-' : '+');

	const int QueryLength = Hit.QueryTo - Hit.QueryFrom + 1;
	int SeqQueryFrom;
	const char *QueryLabel = Glix.GlobalToSeqPadded(Hit.QueryFrom, &SeqQueryFrom);
	const int SeqQueryTo = SeqQueryFrom + QueryLength - 1;

	Rec.SeqName = QueryLabel;
	Rec.Start = SeqQueryFrom + 1;
	Rec.End = SeqQueryTo + 1;

	const int TargetLength = Hit.TargetTo - Hit.TargetFrom + 1;
	int SeqTargetFrom;
	const char *TargetLabel = Glix.GlobalToSeqPadded(Hit.TargetFrom, &SeqTargetFrom);
	const int SeqTargetTo = SeqTargetFrom + TargetLength - 1;
	sprintf(AnnotBuffer, "Target %s %d %d", TargetLabel, SeqTargetFrom + 1, SeqTargetTo + 1);
	Rec.Attrs = AnnotBuffer;
	}
