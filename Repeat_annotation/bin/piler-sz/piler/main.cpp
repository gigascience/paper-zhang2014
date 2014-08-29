#include "piler2.h"

#if	WIN32
#include <windows.h>
#endif

bool g_Quiet = false;
const char *g_ProcessName = "piler2";

int main(int argc, char *argv[])
	{
	g_ProcessName = argv[0];

#if	WIN32
// Multi-tasking does not work well in CPU-bound
// console apps running under Win32.
// Reducing the process priority allows GUI apps
// to run responsively in parallel.
	SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);
#endif

	ProcessArgVect(argc - 1, argv + 1);
	SetLog();
	g_Quiet = FlagOpt("quiet");

	for (int i = 0; i < argc; ++i)
		Log("%s ", argv[i]);
	Log("\n");

	if (ValueOpt("trs") != 0)
		TRS();
	else if (ValueOpt("tan") != 0)
		Tan();
	else if (ValueOpt("tr") != 0)
		TR();
	else if (ValueOpt("trs2fasta"))
		TRS2Fasta();
	else if (ValueOpt("tanmotif2fasta"))
		Tanmotif2Fasta();
	else if (ValueOpt("cons"))
		Cons();
	else if (ValueOpt("annot"))
		Annot();
	else if (ValueOpt("annotedge"))
		AnnotEdge();
	else if (FlagOpt("help"))
		{
		Usage();
		exit(0);
		}
	else if (FlagOpt("version"))
		{
		fprintf(stderr, PILER_LONG_VERSION "\n");
		exit(0);
		}
	else
		CommandLineError("No command specified");
 	}
