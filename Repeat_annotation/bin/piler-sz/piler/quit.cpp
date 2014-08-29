#include "piler2.h"

#ifdef WIN32
#define _WIN32_WINNT 0x0400
#include <windows.h>

void Break()
	{
	DebugBreak();
	}
#endif

// Exit immediately with error message, printf-style.
void Quit(const char szFormat[], ...)
	{
	va_list ArgList;
	char szStr[4096];

	va_start(ArgList, szFormat);
	vsprintf(szStr, szFormat, ArgList);

	fprintf(stderr, "\n*** FATAL ERROR ***  %s %s\n", g_ProcessName, szStr);

	Log("\n*** FATAL ERROR ***  ");
	Log("%s\n", szStr);

#if	DEBUG
#ifdef WIN32
	if (IsDebuggerPresent())
		{
		int iBtn = MessageBox(NULL, szStr, "piler", MB_ICONERROR | MB_OKCANCEL);
		if (IDCANCEL == iBtn)
			Break();
		}
#endif
#endif
	exit(1);
	}
