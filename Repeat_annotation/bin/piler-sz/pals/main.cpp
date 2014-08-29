#include "pals.h"

#if	WIN32
#include <windows.h>
#endif

bool g_Quiet = false;

int main(int argc, char *argv[])
	{
#if	WIN32
// Multi-tasking does not work well in CPU-bound
// console apps running under Win32.
// Reducing the process priority allows GUI apps
// to run responsively in parallel.
	SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);
#endif

	ProcessArgVect(argc - 1, argv + 1);
	SetLog();

	for (int i = 0; i < argc; ++i)
		Log("%s ", argv[i]);
	Log("\n");
	g_Quiet = FlagOpt("quiet");

	if (!g_Quiet)
		Credits();

	if (FlagOpt("help"))
		{
		Usage();
		exit(0);
		}
	else if (FlagOpt("version"))
		{
		fprintf(stderr, PALS_LONG_VERSION "\n");
		exit(0);
		}
	else
		PALS();

	Progress("Elapsed time %d secs, peak mem use %.0f Mb",
	  GetElapsedSecs(),
	  GetPeakMemUseBytes()/1e6);
	}
