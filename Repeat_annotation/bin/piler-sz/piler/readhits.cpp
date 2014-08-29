#include "piler2.h"

// Destructive: pokes Rec.Attrs
static char *GetTarget(GFFRecord &Rec, int *ptrStart, int *ptrEnd)
	{
	char *Attrs = Rec.Attrs;
	char *SemiColon = strchr(Attrs, ';');
	if (0 != SemiColon)
		*SemiColon = 0;
	char *Space = strchr(Attrs, ' ');
	if (0 == Space)
		Quit("GFF hit record line %d, missing space in attrs", GFFLineNr);
	*Space = 0;
	if (0 != strcmp(Attrs, "Target"))
		Quit("GFF hit record line %d, expected Target as first attr", GFFLineNr);
	char *Label = Space + 1;
	Space = strchr(Label, ' ');
	if (0 == Space)
		Quit("GFF hit record line %d, missing space following Target label", GFFLineNr);
	*Space = 0;
	char *Start = Space + 1;
	Space = strchr(Start, ' ');
	if (0 == Space)
		Quit("GFF hit record line %d, missing space following Target start", GFFLineNr);
	*Space = 0;
	char *End = Space + 1;
	*ptrStart = atoi(Start);
	*ptrEnd = atoi(End);
	return Label;
	}

static int ReadHitsPass1(FILE *f)
	{
	GFFLineNr = 0;
	int HitCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "hit"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		int TargetStart;
		int TargetEnd;
		const char *TargetLabel = GetTarget(Rec, &TargetStart, &TargetEnd);
		if (TargetStart <= 0 || TargetEnd <= 0 || TargetStart > TargetEnd)
			Warning("GFF line %d: invalid target start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		++HitCount;
		AddContigPos(Rec.SeqName, Rec.End - 1);
		AddContigPos(TargetLabel, TargetEnd - 1);
		}
	return HitCount;
	}

static int ReadHitsPass2(FILE *f, HitData *Hits)
	{
	rewind(f);

	GFFLineNr = 0;
	int HitCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "hit"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		int TargetStart;
		int TargetEnd;
		const char *TargetLabel = GetTarget(Rec, &TargetStart, &TargetEnd);
		if (TargetStart <= 0 || TargetEnd <= 0 || TargetStart > TargetEnd)
			Warning("GFF line %d: invalid target start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		HitData &Hit = Hits[HitCount];

		const int QueryFrom = ContigToGlobal(Rec.Start, Rec.SeqName);
		const int TargetFrom = ContigToGlobal(TargetStart, TargetLabel);

		const int QueryLength = Rec.End - Rec.Start + 1;
		const int TargetLength = TargetEnd - TargetStart + 1;

		Hit.QueryFrom = QueryFrom;
		Hit.QueryTo = QueryFrom + QueryLength - 1;
		Hit.TargetFrom = TargetFrom;
		Hit.TargetTo = TargetFrom + TargetLength - 1;

		if (Rec.Strand == '+')
			Hit.Rev = false;
		else if (Rec.Strand == '-')
			Hit.Rev = true;
		else
			Quit("GFF line %d, Invalid strand %c", GFFLineNr, Rec.Strand);

		++HitCount;
		}
	return HitCount;
	}

HitData *ReadHits(const char *FileName, int *ptrHitCount, int *ptrSeqLength)
	{
	FILE *f = OpenStdioFile(FileName);

	int HitCount = ReadHitsPass1(f);
	int SeqLength = GlobalizeContigs();
	MakeContigMap();

	HitData *Hits = all(HitData, HitCount);
	ReadHitsPass2(f, Hits);
	fclose(f);

	*ptrSeqLength = SeqLength;
	*ptrHitCount = HitCount;
	return Hits;
	}
