#include "pals.h"

int *MakeContigMap(const ContigData *Contigs, int ContigCount)
	{
	if (ContigCount <= 0)
		return 0;
	const ContigData &LastContig = Contigs[ContigCount-1];
	const int SeqLength = LastContig.From + LastContig.Length - 1;
	const int BinCount = (SeqLength + CONTIG_MAP_BIN_SIZE - 1)/CONTIG_MAP_BIN_SIZE;
	int *Map = all(int, BinCount);

// Initialize, enables correctness check
	for (int i = 0; i < BinCount; ++i)
		Map[i] = -1;

	for (int ContigIndex = 0; ContigIndex < ContigCount; ++ContigIndex)
		{
		const ContigData &Contig = Contigs[ContigIndex];

	// Contig required to start on bin boundary
		const int From = Contig.From;
		if (From%CONTIG_MAP_BIN_SIZE)
			Quit("MakeContigMap: Contig does not start on bin boundary");

		const int To = From + Contig.Length - 1;
		const int BinFrom = From/CONTIG_MAP_BIN_SIZE;
		const int BinTo = To/CONTIG_MAP_BIN_SIZE;

		for (int Bin = BinFrom; Bin <= BinTo; ++Bin)
			{
			if (-1 != Map[Bin])
				Quit("MakeContigMap logic error 1");
			Map[Bin] = ContigIndex;
			}
		}

// Correctness check
	//for (int i = 0; i < BinCount; ++i)
	//	{
	//	if (-1 == Map[i])
	//		Quit("MakeContigMap logic error 2");
	//	}
	return Map;
	}
