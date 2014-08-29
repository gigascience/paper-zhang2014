#include "piler2.h"

// Destructive: pokes Rec.Attrs
static char *GetRepeat(GFFRecord &Rec)
	{
	char *Attrs = Rec.Attrs;
	char *Start = strstr(Attrs, "Repeat");
	if (0 == Start)
		Quit("GFF line %d, repeat record does not have Repeat attribute", GFFLineNr);

	char *SemiColon = strchr(Start, ';');
	if (0 != SemiColon)
		*SemiColon = 0;
	char *Space = strchr(Start, ' ');
	if (0 == Space)
		Quit("GFF repeat record line %d, missing space in attrs", GFFLineNr);
	return Space + 1;
	}

// "Repeat HETRP_DM Satellite 1518 1669 0"
//            0         1       2    3  4
void ParseRepeat(char *Str, RepData &Rep)
	{
	char *Fields[5];
	int FieldCount = GetFields(Str, Fields, 5, ' ');
	if (FieldCount != 5)
		Quit("GFF line %d, Repeat attribute does not have 5 fields");

	const char *RepeatName = Fields[0];
	const char *RepeatClass = Fields[1];
	const char *RepeatFrom = Fields[2];
	const char *RepeatTo = Fields[3];
	const char *RepeatLeft = Fields[4];

	Rep.RepeatName = strsave(RepeatName);
	Rep.RepeatClass = strsave(RepeatClass);
	if (0 == strcmp(RepeatFrom, "."))
		{
		Rep.RepeatFrom = -1;
		Rep.RepeatTo = -1;
		Rep.RepeatLeft = -1;
		}
	else
		{
		Rep.RepeatFrom = atoi(RepeatFrom) - 1;
		Rep.RepeatTo = atoi(RepeatTo) - 1;
		Rep.RepeatLeft = atoi(RepeatLeft);
		}
	}

static int ReadRepsPass1(FILE *f)
	{
	GFFLineNr = 0;
	int RepCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "repeat"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);
		++RepCount;
		}
	return RepCount;
	}

static int ReadRepsPass2(FILE *f, RepData *Reps)
	{
	rewind(f);

	GFFLineNr = 0;
	int RepCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "repeat"))
			continue;

		static char *Repeat = GetRepeat(Rec);

		RepData &Rep = Reps[RepCount];
		ParseRepeat(Repeat, Rep);

		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		const int Length = Rec.End - Rec.Start + 1;

		Rep.ContigLabel = strsave(Rec.SeqName);
		Rep.ContigFrom = Rec.Start - 1;
		Rep.ContigTo = Rep.ContigFrom + Length - 1;

		if (Rec.Strand == '+')
			Rep.Rev = false;
		else if (Rec.Strand == '-')
			Rep.Rev = true;
		else
			Quit("GFF line %d, Invalid strand %c", GFFLineNr, Rec.Strand);

		++RepCount;
		}
	return RepCount;
	}

RepData *ReadReps(const char *FileName, int *ptrRepCount)
	{
	FILE *f = OpenStdioFile(FileName);

	int RepCount = ReadRepsPass1(f);
	RepData *Reps = all(RepData, RepCount);
	ReadRepsPass2(f, Reps);
	fclose(f);

	*ptrRepCount = RepCount;
	return Reps;
	}
