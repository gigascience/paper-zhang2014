#include "piler2.h"

static int GetFam(GFFRecord &Rec)
	{
	char *Attrs = Rec.Attrs;
	char *Pyr = strstr(Attrs, "Pyramid");
	if (0 == Pyr)
		Quit("GFF tandemmotif record line %d, failed to find Pyramid attr", GFFLineNr);

// Pyramid 123
// 012345678
	return atoi(Pyr + 8);
	}

static int ReadMotifPass1(FILE *f)
	{
	GFFLineNr = 0;
	int MotifCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "tandemmotif"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);
		++MotifCount;
		}
	return MotifCount;
	}

static int ReadMotifPass2(FILE *f, MotifData *Motifs)
	{
	rewind(f);

	GFFLineNr = 0;
	int MotifCount = 0;
	GFFRecord Rec;
	while (GetNextGFFRecord(f, Rec))
		{
		if (0 != strcmp(Rec.Feature, "tandemmotif"))
			continue;
		if (Rec.Start <= 0 || Rec.End <= 0 || Rec.Start > Rec.End)
			Warning("GFF line %d: invalid start %d / end %d",
			  GFFLineNr, Rec.Start, Rec.End);

		int FamIndex = GetFam(Rec);

		MotifData &Motif = Motifs[MotifCount];

		const int Length = Rec.End - Rec.Start + 1;

		Motif.ContigLabel = strsave(Rec.SeqName);
		Motif.ContigFrom = Rec.Start - 1;
		Motif.ContigTo = Motif.ContigFrom + Length - 1;
		Motif.FamIndex = FamIndex;

		++MotifCount;
		}
	return MotifCount;
	}

MotifData *ReadMotif(const char *FileName, int *ptrMotifCount)
	{
	FILE *f = OpenStdioFile(FileName);

	int MotifCount = ReadMotifPass1(f);
	MotifData *Motifs = all(MotifData, MotifCount);
	ReadMotifPass2(f, Motifs);
	fclose(f);

	*ptrMotifCount = MotifCount;
	return Motifs;
	}
