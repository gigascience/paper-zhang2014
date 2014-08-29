#include "pals.h"
#include <time.h>

static time_t g_StartTime = time(0);
static time_t g_StartTimeStep;
static char *g_Desc = 0;

static void ProgressPrefix()
	{
	int ElapsedSecs = (int) (time(0) - g_StartTime);
	unsigned MemUseMB = (GetMemUseBytes() + 500000)/1000000;
	unsigned RAMMB = (unsigned) ((GetRAMSize() + 500000)/1000000);
	unsigned MemUsePct = (MemUseMB*100)/RAMMB;

	fprintf(stderr, "%6d secs  %6d Mb (%3d%%) ", ElapsedSecs, MemUseMB, MemUsePct);
	Log("%6d secs  %6d Mb (%3d%%) ", ElapsedSecs, MemUseMB, MemUsePct);
	}

void ProgressStart(const char *Format, ...)
	{
	ProgressPrefix();

	g_StartTimeStep = time(0);
	char Str[4096];
	va_list ArgList;
	va_start(ArgList, Format);
	vsprintf(Str, Format, ArgList);
	if (g_Desc != 0)
		free(g_Desc);
	g_Desc = strsave(Str);
	fprintf(stderr, "%s\n", Str);
	Log("%s\n", Str);
	}

void ProgressDone()
	{
	if (0 == g_Desc)
		return;

	ProgressPrefix();

	int Secs = (int) (time(0) - g_StartTimeStep);
	fprintf(stderr, "%s done (%ds).\n", g_Desc, Secs);
	Log("%s done (%ds).\n", g_Desc, Secs);
	}

void Progress(const char *Format, ...)
	{
	char Str[4096];
	va_list ArgList;
	va_start(ArgList, Format);
	vsprintf(Str, Format, ArgList);
	fprintf(stderr, "%s\n", Str);
	Log("%s\n", Str);
	}

int GetElapsedSecs()
	{
	return (int) (time(0) - g_StartTime);
	}
