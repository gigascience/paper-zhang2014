#include "piler2.h"

#include <sys/time.h>
#include <sys/resource.h>
#include <sys/unistd.h>

double GetRAMSize()
	{
	struct rlimit RL;
	int Ok = getrlimit(RLIMIT_DATA, &RL);
	if (Ok != 0)
		return 1e9;
	return RL.rlim_cur;
	}

static unsigned g_uPeakMemUseBytes = 1000000;

unsigned GetPeakMemUseBytes()
	{
	return g_uPeakMemUseBytes;
	}

unsigned GetMemUseBytes()
	{
	struct rusage RU;
	int Ok = getrusage(RUSAGE_SELF, &RU);
	if (Ok != 0)
		return 1000000;

	unsigned Bytes = RU.ru_maxrss*1000;
	if (Bytes > g_uPeakMemUseBytes)
		g_uPeakMemUseBytes = Bytes;
	return Bytes;
	}
