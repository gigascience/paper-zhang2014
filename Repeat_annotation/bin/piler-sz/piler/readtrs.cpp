#include "piler2.h"

// Destructive: pokes Rec.Attrs
static char *GetFam(GFFRecord &Rec)
	{
	char *Attrs = Rec.Attrs;
	char *SemiColon = strchr(Attrs, ';');
	if (0 != SemiColon)
		*SemiColon = 0;
	char *Space = strchr(Attrs, ' ');
	if (0 == Space)
		Quit("GFF trs record line %d, missing space in attrs", GFFLineNr);
	*Space = 0;
	if (0 != strcmp(Attrs, "Family"))
		Quit("GFF trs record line %d, expected Family as first attr", GFFLineNr);
	return Space + 1;
	}

static int ReadTRSPass1(FILE *f)
	{
	GFFLineNr = 0;
	int TRSCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "trs"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);
		++TRSCount;
		}
	return TRSCount;
	}

static int ReadTRSPass2(FILE *f, TRSData *TRSs)
	{
	rewind(f);

	GFFLineNr = 0;
	int TRSCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "trs"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		static char *Fam = GetFam(Rec);

		int FamIndex = 0;
		int SuperFamIndex = 0;
		int n = sscanf(Fam, "%d.%d", &FamIndex, &SuperFamIndex);
		if (n != 2)
			Quit("Invalid Family %s", Fam);

		TRSData &TRS = TRSs[TRSCount];

		const int Length = Rec.End - Rec.Start + 1;

		TRS.ContigLabel = strsave(Rec.SeqName);
		TRS.ContigFrom = Rec.Start - 1;
		TRS.ContigTo = TRS.ContigFrom + Length - 1;
		TRS.FamIndex = FamIndex;
		TRS.SuperFamIndex = SuperFamIndex;

		if (Rec.Strand == '+')
			TRS.Rev = false;
		else if (Rec.Strand == '-')
			TRS.Rev = true;
		else
			Quit("GFF line %d, Invalid strand %c", GFFLineNr, Rec.Strand);

		++TRSCount;
		}
	return TRSCount;
	}

TRSData *ReadTRS(const char *FileName, int *ptrTRSCount)
	{
	FILE *f = OpenStdioFile(FileName);

	int TRSCount = ReadTRSPass1(f);
	TRSData *TRSs = all(TRSData, TRSCount);
	ReadTRSPass2(f, TRSs);
	fclose(f);

	*ptrTRSCount = TRSCount;
	return TRSs;
	}
