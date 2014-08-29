#include "piler2.h"

void Credits()
	{
	static bool Displayed = false;
	if (Displayed)
		return;

	fprintf(stderr, "\n" PILER_LONG_VERSION "\n");
	fprintf(stderr, "http://www.drive5.com/piler\n");
	fprintf(stderr, "Written by Robert C. Edgar\n");
	fprintf(stderr, "This software is donated to the public domain.\n");
	fprintf(stderr, "Please visit web site for requested citation.\n");
	Displayed = true;
	}

void Usage()
	{
	Credits();
	fprintf(stderr,
"\n"
"Usage:\n"
"  piler -trs <hitfile> -out <trsfile> [options]\n"
"  piler -trs2fasta <trsfile> -seq <fastafile> [-path <path>] [-maxfam <maxfam>]\n"
"  piler -cons <alnfile> -out <fastafile> -label <label>\n"
"  piler -annot <gff> -rep <repfile> -out <annotfile>\n"
"  piler -help\n"
"  piler -version\n"
"\n"
"Use -quiet to suppress progress messages\n"
"\n"
"-trs options:\n"
"  -mincover <n>\n"
"  -maxlengthdiffpct <n>\n"
"  -piles <pilefile>\n"
"  -images <imagefile>\n"
"  -multihit\n"
"\n"
"For further information, please see the User Guide.\n");
	}
