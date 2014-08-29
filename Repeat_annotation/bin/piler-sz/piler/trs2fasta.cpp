#include "piler2.h"

static void LogRecords(const TRSData *TRSs, int TRSCount)
	{
	Log("              Contig        From          To  Length  +  Family\n");
	Log("--------------------  ----------  ----------  ------  -  ------\n");
	for (int TRSIndex = 0; TRSIndex < TRSCount; ++TRSIndex)
		{
		const TRSData &TRS = TRSs[TRSIndex];
		Log("%20.20s  %10d  %10d  %6d  %c  %d.%d\n",
		  TRS.ContigLabel,
		  TRS.ContigFrom,
		  TRS.ContigTo,
		  TRS.ContigTo - TRS.ContigFrom + 1,
		  TRS.Rev ? '-' : '+',
		  TRS.SuperFamIndex,
		  TRS.FamIndex);
		}
	}

static int CmpTRS(const void *s1, const void *s2)
	{
	const TRSData *TRS1 = (const TRSData *) s1;
	const TRSData *TRS2 = (const TRSData *) s2;
	return TRS1->FamIndex - TRS2->FamIndex;
	}

static char *FamFileName(const char *Path, int Fam, int SuperFam)
	{
	static char FileName[256];
	char s[128];
	sprintf(s, "/%d.%d", SuperFam, Fam);
	if (strlen(Path) + strlen(s) + 3 >= sizeof(FileName))
		Quit("Path name too long");
	strcpy(FileName, Path);
	strcat(FileName, s);
	return FileName;
	}

static char *TRSLabel(const char *Prefix, const TRSData &TRS)
	{
	int n = (int) strlen(TRS.ContigLabel) + 128;
	char *s = all(char, n);
	if (0 != Prefix)
		sprintf(s, "%s.%d.%d %s:%d%c",
		  Prefix,
		  TRS.SuperFamIndex,
		  TRS.FamIndex,
		  TRS.ContigLabel,
		  TRS.ContigFrom+1,
		  TRS.Rev ? '-' : '+');
	else
		sprintf(s, "%d.%d %s:%d%c",
		  TRS.SuperFamIndex,
		  TRS.FamIndex,
		  TRS.ContigLabel,
		  TRS.ContigFrom+1,
		  TRS.Rev ? '-' : '+');
	return s;
	}

void TRS2Fasta()
	{
	const char *TRSFileName = RequiredValueOpt("trs2fasta");
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

	ProgressStart("Read TRS file");
	int TRSCount;
	TRSData *TRSs = ReadTRS(TRSFileName, &TRSCount);
	ProgressDone();

	Progress("%d records", TRSCount);

	ProgressStart("Sorting by family");
	qsort((void *) TRSs, TRSCount, sizeof(TRSData), CmpTRS);
	ProgressDone();

	FILE *f = 0;
	int CurrentFamily = -1;
	int MemberCount = 0;
	for (int TRSIndex = 0; TRSIndex < TRSCount; ++TRSIndex)
		{
		const TRSData &TRS = TRSs[TRSIndex];
		if (TRS.FamIndex != CurrentFamily)
			{
			if (f != 0)
				fclose(f);
			char *FastaFileName = FamFileName(Path, TRS.FamIndex, TRS.SuperFamIndex);
			f = OpenStdioFile(FastaFileName, FILEIO_MODE_WriteOnly);
			CurrentFamily = TRS.FamIndex;
			MemberCount = 0;
			}
		++MemberCount;
		if (MemberCount > MaxFam)
			continue;
		const int From = ContigToGlobal(TRS.ContigFrom, TRS.ContigLabel);
		const int Length = TRS.ContigTo - TRS.ContigFrom + 1;
		char *Label = TRSLabel(Prefix, TRS);
		WriteFasta(f, Seq + From, Length, Label, TRS.Rev);
		freemem(Label);
		}
	}
