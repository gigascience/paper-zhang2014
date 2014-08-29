#include "piler2.h"

static void LogRecords(const MotifData *Motifs, int MotifCount)
	{
	Log("              Contig        From          To  Length  Family\n");
	Log("--------------------  ----------  ----------  ------  ------\n");
	for (int MotifIndex = 0; MotifIndex < MotifCount; ++MotifIndex)
		{
		const MotifData &Motif = Motifs[MotifIndex];
		Log("%20.20s  %10d  %10d  %6d  %d\n",
		  Motif.ContigLabel,
		  Motif.ContigFrom,
		  Motif.ContigTo,
		  Motif.ContigTo - Motif.ContigFrom + 1,
		  Motif.FamIndex);
		}
	}

static int CmpMotif(const void *s1, const void *s2)
	{
	const MotifData *Motif1 = (const MotifData *) s1;
	const MotifData *Motif2 = (const MotifData *) s2;
	return Motif1->FamIndex - Motif2->FamIndex;
	}

static char *FamFileName(const char *Path, int Fam)
	{
	static char FileName[256];
	char s[128];
	sprintf(s, "/%d", Fam);
	if (strlen(Path) + strlen(s) + 3 >= sizeof(FileName))
		Quit("Path name too long");
	strcpy(FileName, Path);
	strcat(FileName, s);
	return FileName;
	}

static char *MotifLabel(const char *Prefix, const MotifData &Motif)
	{
	int n = (int) strlen(Motif.ContigLabel) + 128;
	char *s = all(char, n);
	if (0 != Prefix)
		sprintf(s, "%s.%d %s:%d",
		  Prefix,
		  Motif.FamIndex,
		  Motif.ContigLabel,
		  Motif.ContigFrom+1);
	else
		sprintf(s, "%d %s:%d",
		  Motif.FamIndex,
		  Motif.ContigLabel,
		  Motif.ContigFrom+1);
	return s;
	}

void Tanmotif2Fasta()
	{
	const char *MotifFileName = RequiredValueOpt("tanmotif2fasta");
	const char *SeqFileName = RequiredValueOpt("seq");
	const char *Path = ValueOpt("path");
	const char *strMaxFam = ValueOpt("maxfam");
	const char *Prefix = ValueOpt("prefix");

	int MaxFam = DEFAULT_MAX_FAM;
	if (strMaxFam != 0)
		MaxFam = atoi(strMaxFam);

	if (0 == Path)
		Path = ".";

	ProgressStart("Reading seq file");
	int SeqLength;
	const char *Seq = ReadMFA(SeqFileName, &SeqLength);
	ProgressDone();

	Progress("Seq length %d bases, %.3g Mb", SeqLength, SeqLength/1e6);

	ProgressStart("Read Motif file");
	int MotifCount;
	MotifData *Motifs = ReadMotif(MotifFileName, &MotifCount);
	ProgressDone();

	Progress("%d records", MotifCount);

	ProgressStart("Sorting by family");
	qsort((void *) Motifs, MotifCount, sizeof(MotifData), CmpMotif);
	ProgressDone();

	FILE *f = 0;
	int CurrentFamily = -1;
	int MemberCount = 0;
	for (int MotifIndex = 0; MotifIndex < MotifCount; ++MotifIndex)
		{
		const MotifData &Motif = Motifs[MotifIndex];
		if (Motif.FamIndex != CurrentFamily)
			{
			if (f != 0)
				fclose(f);
			char *FastaFileName = FamFileName(Path, Motif.FamIndex);
			f = OpenStdioFile(FastaFileName, FILEIO_MODE_WriteOnly);
			CurrentFamily = Motif.FamIndex;
			MemberCount = 0;
			}
		++MemberCount;
		if (MemberCount > MaxFam)
			continue;
		const int From = ContigToGlobal(Motif.ContigFrom, Motif.ContigLabel);
		const int Length = Motif.ContigTo - Motif.ContigFrom + 1;
		char *Label = MotifLabel(Prefix, Motif);
		WriteFasta(f, Seq + From, Length, Label, false);
		freemem(Label);
		}
	}
