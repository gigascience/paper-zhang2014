#include "piler2.h"

// GFF fields are:
// <seqname> <source> <feature> <start> <end> <score> <strand> <frame> [attributes] [comments]
//     0         1         2        3      4      5        6       7         8           9

int GFFLineNr;

// Destructive read -- pokes nuls onto FS
int GetFields(char *Line, char **Fields, int MaxFields, char FS)
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
			  FieldLength, MAX_GFF_FEATURE_LENGTH, GFFLineNr);
		if (0 == Tab)
			return FieldIndex + 1;
		*Tab = 0;
		p = Tab + 1;
		}
	return MaxFields;
	}

bool GetNextGFFRecord(FILE *f, GFFRecord &Rec)
	{
	for (;;)
		{
		++GFFLineNr;
		const char TAB = '\t';
		char Line[MAX_GFF_LINE+1];
		char *Ok = fgets(Line, sizeof(Line), f);
		if (NULL == Ok)
			{
			if (feof(f))
				return false;
			Quit("Error reading GFF file, line=%d feof=%d ftell=%d ferror=%d errno=%d",
			  GFFLineNr, feof(f), ftell(f), ferror(f), errno);
			}
		if ('#' == Line[0])
			continue;
		size_t n = strlen(Line);
		if (0 == n)
			Quit("fgets returned zero-length line");
		if (Line[n-1] != '\n')
			Quit("Max line length in GFF file exceeded, line %d is %d chars long, max=%d",
			  GFFLineNr, n - 1, MAX_GFF_LINE);
		Line[n-1] = 0;	// delete newline

		char *Fields[9];
		int FieldCount = GetFields(Line, Fields, 9, '\t');
		if (FieldCount < 8)
			Quit("GFF record has < 8 fields, line %d", GFFLineNr);

		const char *SeqName = Fields[0];
		const char *Source = Fields[1];
		const char *Feature = Fields[2];
		const char *Start = Fields[3];
		const char *End = Fields[4];
		const char *Score = Fields[5];
		const char *Strand = Fields[6];
		const char *Frame = Fields[7];
		const char *Attrs = Fields[8];

	// Truncate attrs if comment found
		char *Pound = strchr(Attrs, '#');
		if (0 != Pound)
			*Pound = 0;

		strcpy(Rec.SeqName, SeqName);
		strcpy(Rec.Source, Source);
		strcpy(Rec.Feature, Feature);
		Rec.Start = atoi(Start);
		Rec.End = atoi(End);
		Rec.Score = (float) atof(Score);
		Rec.Strand = Strand[0];
		Rec.Frame = Frame[0] == '.' ? -1 : atoi(Frame);
		strcpy(Rec.Attrs, Attrs);
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
