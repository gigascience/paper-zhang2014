#include "pals.h"

void Credits()
	{
	static bool Displayed = false;
	if (Displayed)
		return;

	fprintf(stderr, "\n" PALS_LONG_VERSION "\n");
	fprintf(stderr, "http://www.drive5.com/pals\n");
	fprintf(stderr, "Written by Bob Edgar and Gene Myers.\n");
	fprintf(stderr, "This software is donated to the public domain.\n");
	fprintf(stderr, "Please visit web site for requested citation.\n\n");
	Displayed = true;
	}

void Usage()
	{
	Credits();
	fprintf(stderr,
"\n"
"Usage:\n"
"    pals -target <fastafile> -query <fastafile>\n"
"    pals -self <fastafile>\n"
"\n"
"Options:\n"
"    -out <outfile>       (default standard output)\n"
"    -fwdonly             don't align reverse strand\n"
"    -filterout <file>    save filter hits to file\n"
"\n"
"Alignment parameters can be specified in three ways:\n"
"    (1) Defaults         -length 400 -pctid 94\n"
"    (2) Specify -length <minhitlength> -pctid <minhitid>\n"
"    (3) Specify all filter and d.p. parameters:\n"
"           -wordsize     Filter word size\n"
"           -seedlength   Seed hit length\n"
"           -seeddiffs    Max #diffs in seed hit\n"
"           -length       Min length of final hit\n"
"           -pctid        Min %%id of final hit\n"
"           -tubeoffset   (Optional)\n"
"\n"
"For further information, please see the User Guide.\n");
	}
