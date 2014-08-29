#include "piler2.h"

#ifdef	_MSC_VER
#include <crtdbg.h>
#endif

static int AllocatedBytes;
static int PeakAllocatedBytes;

// Allocate memory, fail on error, track total
void *allocmem(int bytes)
	{
	assert(bytes < 0xfffffff0);		// check for overlow
	char *p = (char *) malloc((size_t) (bytes + 4));
	if (0 == p)
		Quit("Out of memory (%d)", bytes);
	int *pSize = (int *) p;
	*pSize = bytes;
	AllocatedBytes += bytes;
	if (AllocatedBytes > PeakAllocatedBytes)
		PeakAllocatedBytes = AllocatedBytes;
	return p + 4;
	}

void freemem(void *p)
	{
	if (0 == p)
		return;
	int *pSize = (int *) ((char *) p - 4);
	int bytes = *pSize;
	assert(bytes <= AllocatedBytes);
	AllocatedBytes -= bytes;
	free(((char *) p) - 4);
	}

void chkmem()
	{
#ifdef	_MSC_VER
	assert(_CrtCheckMemory());
#endif
	}

void *reallocmem(void *p, int bytes)
	{
	if (0 == p)
		return allocmem(bytes);

	int *pSize = (int *) ((char *) p - 4);
	int oldbytes = *pSize;
	void *newp = allocmem(bytes);
	memcpy(newp, p, oldbytes);
	return newp;
	}
