#include "piler2.h"

struct VALUE_OPT
	{
	const char *m_pstrName;
	const char *m_pstrValue;
	};

struct FLAG_OPT
	{
	const char *m_pstrName;
	bool m_bSet;
	};

static VALUE_OPT ValueOpts[] =
	{
	"trs",					0,
	"trs2",					0,
	"trs2fasta",			0,
	"tanmotif2fasta",		0,
	"cons",					0,
	"out",					0,
	"piles",				0,
	"images",				0,
	"log",					0,
	"loga",					0,
	"seq",					0,
	"path",					0,
	"rep",					0,
	"mincover",				0,
	"maxlengthdiffpct",		0,
	"maxfam",				0,
	"label",				0,
	"annot",				0,
	"annotedge",			0,
	"famsize",				0,
	"prefix",				0,
	"tan",					0,
	"pyramid",				0,
	"motif",				0,
	"minhits",				0,
	"maxmargin",			0,
	"minratio",				0,
	"tr",					0,
	"cand",					0,
	"mintrspacing",			0,
	"maxtrspacing",			0,
	"mintrlength",			0,
	"minspacingratio",		0,
	"minfam",				0,
	"minhitratio",			0,
	"mindistpairs",			0,
	};
static int ValueOptCount = sizeof(ValueOpts)/sizeof(ValueOpts[0]);

static FLAG_OPT FlagOpts[] =
	{
	"multihit",				0,
	"quiet",				0,
	"version",				0,
	"help",					0,
	"edge",					0,
	"pilesonly",			0,
	};
static int FlagOptCount = sizeof(FlagOpts)/sizeof(FlagOpts[0]);

void CommandLineError(const char *Format, ...)
	{
	va_list ArgList;
	va_start(ArgList, Format);

	char Str[4096];
	vsprintf(Str, Format, ArgList);
	Usage();
	fprintf(stderr, "\n** Command line error** %s\n", Str);
	exit(1);
	}

static bool TestSetFlagOpt(const char *Arg)
	{
	for (int i = 0; i < FlagOptCount; ++i)
		if (!stricmp(Arg, FlagOpts[i].m_pstrName))
			{
			FlagOpts[i].m_bSet = true;
			return true;
			}
	return false;
	}

static bool TestSetValueOpt(const char *Arg, const char *Value)
	{
	for (int i = 0; i < ValueOptCount; ++i)
		if (!stricmp(Arg, ValueOpts[i].m_pstrName))
			{
			if (0 == Value)
				CommandLineError("Option -%s must have value\n", Arg);
			ValueOpts[i].m_pstrValue = strsave(Value);
			return true;
			}
	return false;
	}

bool FlagOpt(const char *Name)
	{
	for (int i = 0; i < FlagOptCount; ++i)
		if (!stricmp(Name, FlagOpts[i].m_pstrName))
			return FlagOpts[i].m_bSet;
	Quit("FlagOpt(%s) invalid", Name);
	return false;
	}

const char *ValueOpt(const char *Name)
	{
	for (int i = 0; i < ValueOptCount; ++i)
		if (!stricmp(Name, ValueOpts[i].m_pstrName))
			return ValueOpts[i].m_pstrValue;
	Quit("ValueOpt(%s) invalid", Name);
	return 0;
	}

const char *RequiredValueOpt(const char *Name)
	{
	const char *s = ValueOpt(Name);
	if (0 == s)
		CommandLineError("Required option -%s not specified\n", Name);
	return s;
	}

void ProcessArgVect(int argc, char *argv[])
	{
	for (int iArgIndex = 0; iArgIndex < argc; )
		{
		const char *Arg = argv[iArgIndex];
		if (Arg[0] != '-')
			Quit("Command-line option \"%s\" must start with '-'\n", Arg);
		const char *ArgName = Arg + 1;
		if (TestSetFlagOpt(ArgName))
			{
			++iArgIndex;
			continue;
			}
		
		char *Value = 0;
		if (iArgIndex < argc - 1)
			Value = argv[iArgIndex+1];
		if (TestSetValueOpt(ArgName, Value))
			{
			iArgIndex += 2;
			continue;
			}
		CommandLineError("Invalid command line option \"%s\"\n", ArgName);
		}
	}
