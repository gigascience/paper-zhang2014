#include "piler2.h"

void Annot()
	{
	const char *InputFileName = RequiredValueOpt("annot");
	const char *RepeatFileName = RequiredValueOpt("rep");
	const char *OutputFileName = RequiredValueOpt("out");

	ProgressStart("Reading repeat file");
	int RepCount;
	RepData *Reps = ReadReps(RepeatFileName, &RepCount);
	ProgressDone();

	Progress("%d records", RepCount);

	FILE *fInput = OpenStdioFile(InputFileName);
	FILE *fOutput = OpenStdioFile(OutputFileName, FILEIO_MODE_WriteOnly);

	ProgressStart("Transferring annotation");
	GFFRecord Rec;
	while (GetNextGFFRecord(fInput, Rec))
		{
		const bool Rev = Rec.Strand == '-';
		const char *Annot = MakeAnnot(Rec.SeqName, Rec.Start-1, Rec.End-1, Rev,
		  Reps, RepCount);

		fprintf(fOutput, "%s\t%s\t%s\t%d\t%d\t%.3g\t%c",
		//                0   1   2   3   4   5     6
		  Rec.SeqName,	// 0
		  Rec.Source,	// 1
		  Rec.Feature,	// 2
		  Rec.Start,	// 3
		  Rec.End,		// 4
		  Rec.Score,	// 5
		  Rec.Strand);	// 6

		if (-1 == Rec.Frame)
			fprintf(fOutput, "\t.");
		else
			fprintf(fOutput, "\t%d", Rec.Frame);

		fprintf(fOutput, "\t%s ; Annot \"%s\"\n", Rec.Attrs, Annot);
		}
	fclose(fInput);
	fclose(fOutput);
	ProgressDone();
	}
