#include "piler2.h"
#include "bitfuncs.h"

#define TRACE		0

static int g_paramMinFamSize = 3;
static int g_paramMaxLengthDiffPct = 5;
static bool g_paramSingleHitCoverage = true;

static PileData *Piles;
static int PileCount;
static int EdgeCount;

static int MaxImageCount = 0;
static int SeqLength;
static int SeqLengthChunks;

static PILE_INDEX_TYPE *IdentifyPiles(int *CopyCount)
	{
	PILE_INDEX_TYPE *PileIndexes = all(PILE_INDEX_TYPE, SeqLengthChunks);

#if	DEBUG
	memset(PileIndexes, 0xff, SeqLengthChunks*sizeof(PILE_INDEX_TYPE));
#endif

	int PileIndex = -1;
	bool InPile = false;
	for (int i = 0; i < SeqLengthChunks; ++i)
		{
		if (BitIsSet(CopyCount, i))
			{
			if (!InPile)
				{
				++PileIndex;
				if (PileIndex > MAX_STACK_INDEX)
					Quit("Too many stacks");
				InPile = true;
				}
			PileIndexes[i] = PileIndex;
			}
		else
			InPile = false;
		}
	PileCount = PileIndex + 1;
	return PileIndexes;
	}

static void IncCopyCountImage(int *CopyCount, int From, int To)
	{
	if (From < 0)
		Quit("From < 0");

	From /= CHUNK_LENGTH;
	To /= CHUNK_LENGTH;

	if (From >= SeqLengthChunks)
		{
		Warning("IncCopyCountImage: From=%d, SeqLength=%d", From, SeqLengthChunks);
		From = SeqLengthChunks - 1;
		}
	if (To >= SeqLengthChunks)
		{
		Warning("IncCopyCountImage: To=%d, SeqLength=%d", To, SeqLengthChunks);
		To = SeqLengthChunks - 1;
		}

	if (From > To)
		Quit("From > To");

	for (int i = From; i <= To; ++i)
		SetBit(CopyCount, i);
	}

static void IncCopyCount(int *CopyCount, const HitData &Hit)
	{
	IncCopyCountImage(CopyCount, Hit.TargetFrom, Hit.TargetTo);
	IncCopyCountImage(CopyCount, Hit.QueryFrom, Hit.QueryTo);
	}

static int CmpHits(const void *ptrHit1, const void *ptrHit2)
	{
	HitData *Hit1 = (HitData *) ptrHit1;
	HitData *Hit2 = (HitData *) ptrHit2;
	return Hit1->QueryFrom - Hit2->QueryFrom;
	}

static int CmpImages(const void *ptrImage1, const void *ptrImage2)
	{
	PileImageData *Image1 = (PileImageData *) ptrImage1;
	PileImageData *Image2 = (PileImageData *) ptrImage2;
	return Image1->SIPile - Image2->SIPile;
	}

static void AssertImagesSorted(PileImageData *Images, int ImageCount)
	{
	for (int i = 0; i < ImageCount - 1; ++i)
		if (Images[i].SIPile > Images[i+1].SIPile)
			Quit("Images not sorted");
	}

static void SortImagesPile(PileImageData *Images, int ImageCount)
	{
	qsort(Images, ImageCount, sizeof(PileImageData), CmpImages);
	}

static void SortImages()
	{
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		PileData &Pile = Piles[PileIndex];
		SortImagesPile(Pile.Images, Pile.ImageCount);
#if	DEBUG
		AssertImagesSorted(Pile.Images, Pile.ImageCount);
#endif
		}
	}

static void CreatePiles(const HitData *Hits, int HitCount,
  PILE_INDEX_TYPE *PileIndexes)
	{
	Piles = all(PileData, PileCount);
	zero(Piles, PileData, PileCount);
	for (int i = 0; i < PileCount; ++i)
		{
		Piles[i].FamIndex = -1;
		Piles[i].SuperFamIndex = -1;
		Piles[i].Rev = -1;
		}

// Count images in stack
	ProgressStart("Create stacks: count images");
	for (int HitIndex = 0; HitIndex < HitCount; ++HitIndex)
		{
		const HitData &Hit = Hits[HitIndex];

		int Pos = Hit.QueryFrom/CHUNK_LENGTH;
		PILE_INDEX_TYPE PileIndex = PileIndexes[Pos];
		assert(PileIndex == PileIndexes[Hit.QueryTo/CHUNK_LENGTH]);
		assert(PileIndex >= 0 && PileIndex < PileCount);
		++(Piles[PileIndex].ImageCount);

		Pos = Hit.TargetFrom/CHUNK_LENGTH;
		PileIndex = PileIndexes[Pos];
		assert(PileIndex >= 0 && PileIndex < PileCount);
		assert(PileIndex == PileIndexes[Hit.TargetTo/CHUNK_LENGTH]);
		++(Piles[PileIndex].ImageCount);
		}
	ProgressDone();

// Allocate memory for image list
	int TotalImageCount = 0;
	ProgressStart("Create stacks: allocate image memory");
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		PileData &Pile = Piles[PileIndex];
		const int ImageCount = Pile.ImageCount;
		TotalImageCount += ImageCount;
		assert(ImageCount > 0);
		Pile.Images = all(PileImageData, ImageCount);
		}
	ProgressDone();

// Build image list
	ProgressStart("Create stacks: build image list");
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		PileData &Pile = Piles[PileIndex];
		Pile.ImageCount = 0;
		Pile.From = -1;
		Pile.To = -1;
		}

	for (int HitIndex = 0; HitIndex < HitCount; ++HitIndex)
		{
		const HitData &Hit = Hits[HitIndex];

		const bool Rev = Hit.Rev;

		const int Length1 = Hit.QueryTo - Hit.QueryFrom;
		const int Length2 = Hit.TargetTo - Hit.TargetFrom;

		const int From1 = Hit.QueryFrom;
		const int From2 = Hit.TargetFrom;

		const int To1 = Hit.QueryTo;
		const int To2 = Hit.TargetTo;

		const int Pos1 = From1/CHUNK_LENGTH;
		const int Pos2 = From2/CHUNK_LENGTH;

		PILE_INDEX_TYPE PileIndex1 = PileIndexes[Pos1];
		PILE_INDEX_TYPE PileIndex2 = PileIndexes[Pos2];

		assert(PileIndex1 == PileIndexes[(From1 + Length1 - 1)/CHUNK_LENGTH]);
		assert(PileIndex1 >= 0 && PileIndex1 < PileCount);

		assert(PileIndex2 == PileIndexes[(From2 + Length2 - 1)/CHUNK_LENGTH]);
		assert(PileIndex2 >= 0 && PileIndex2 < PileCount);

		PileData &Pile1 = Piles[PileIndex1];
		PileImageData &Image1 = Pile1.Images[Pile1.ImageCount++];
		Image1.SILength = Length2;
		Image1.SIPile = PileIndex2;
		Image1.SIRev = Rev;

		PileData &Pile2 = Piles[PileIndex2];
		PileImageData &Image2 = Pile2.Images[Pile2.ImageCount++];
		Image2.SILength = Length1;
		Image2.SIPile = PileIndex1;
		Image2.SIRev = Rev;

		if (Pile1.From == -1 || From1 < Pile1.From)
			Pile1.From = From1;
		if (Pile1.To == -1 || To1 > Pile1.To)
			Pile1.To = To1;

		if (Pile2.From == -1 || From2 < Pile2.From)
			Pile2.From = From2;
		if (Pile2.To == -1 || To2 > Pile2.To)
			Pile2.To = To2;

		if (Pile1.ImageCount > MaxImageCount)
			MaxImageCount = Pile1.ImageCount;
		if (Pile2.ImageCount > MaxImageCount)
			MaxImageCount = Pile2.ImageCount;
		}
	ProgressDone();
	}

static int FindGlobalEdgesPileMulti(PileData &Pile, int PileIndex,
  PILE_INDEX_TYPE Partners[], bool PartnersRev[])
	{
	const int PileLength = Pile.To - Pile.From + 1;
	const int MinLength = (PileLength*(100 - g_paramMaxLengthDiffPct))/100;
	const int MaxLength = (PileLength*(100 + g_paramMaxLengthDiffPct))/100;

	const int ImageCount = Pile.ImageCount;
	SortImagesPile(Pile.Images, ImageCount);

#if	TRACE
	Log("Pile1  Pile2  Pile1L  Pile2L  Fract1  Fract2  Global [Multi]\n");
	Log("------  ------  -------  -------  ------  ------  ------\n");
#endif

	int CurrentPartnerPileIndex = -1;
	int BasesCovered = 0;
	int PartnerCount = 0;
	for (int ImageIndex = 0; ; ++ImageIndex)
		{
		int PartnerPileIndex;
		int ImageLength = 0;
		bool Rev = false;
		if (ImageIndex < ImageCount)
			{
			const PileImageData &Image = Pile.Images[ImageIndex];
			PartnerPileIndex = Image.SIPile;
			ImageLength = Image.SILength;
			Rev = Image.SIRev;
			}
		else
			PartnerPileIndex = -1;

		if (PartnerPileIndex == CurrentPartnerPileIndex)
			BasesCovered += ImageLength;
		else
			{
			if (CurrentPartnerPileIndex != -1)
				{
				const PileData &PartnerPile = Piles[CurrentPartnerPileIndex];
				const int PartnerPileLength = PartnerPile.To - PartnerPile.From + 1;
				bool IsGlobalMatch = 
				  PartnerPileLength >= MinLength && PartnerPileLength <= MaxLength &&
				  BasesCovered >= MinLength && PartnerPileIndex != PileIndex;
#if	TRACE
				Log("%6d  %6d  %7d  %7d  %5.0f%%  %5.0f%%  %c\n",
				  PileIndex,
				  CurrentPartnerPileIndex,
				  PileLength,
				  PartnerPileLength,
				  (BasesCovered*100.0)/PileLength,
				  (BasesCovered*100.0)/PartnerPileLength,
				  IsGlobalMatch ? 'Y' : 'N');
#endif
				if (IsGlobalMatch)
					{
					PartnersRev[PartnerCount] = Rev; // TODO
					Partners[PartnerCount] = CurrentPartnerPileIndex;
					++PartnerCount;
					}
				}
			CurrentPartnerPileIndex = PartnerPileIndex;
			BasesCovered = ImageLength;
			}
		if (ImageIndex == ImageCount)
			break;
		}
	return PartnerCount;
	}

static int FindGlobalEdgesPileSingle(PileData &Pile, int PileIndex,
  PILE_INDEX_TYPE Partners[], bool PartnersRev[])
	{
	const int ImageCount = Pile.ImageCount;
	const int PileLength = Pile.To - Pile.From + 1;

	const int MinLength = (PileLength*(100 - g_paramMaxLengthDiffPct))/100;
	const int MaxLength = (PileLength*(100 + g_paramMaxLengthDiffPct))/100;

#if	TRACE
	Log("Pile1  Pile2  Pile1L  Pile2L  Fract1  Fract2  Global [Single]\n");
	Log("------  ------  -------  -------  ------  ------  ------\n");
#endif
	int PartnerCount = 0;
	for (int ImageIndex = 0; ImageIndex < ImageCount; ++ImageIndex)
		{
		const PileImageData &Image = Pile.Images[ImageIndex];
		const int PartnerImageLength = Image.SILength;
		const int PartnerPileIndex = Image.SIPile;
		const PileData &PartnerPile = Piles[PartnerPileIndex];
		const int PartnerPileLength = PartnerPile.To - PartnerPile.From + 1;

		bool IsGlobalImage = 
		  PartnerPileLength >= MinLength && PartnerPileLength <= MaxLength &&
		  PartnerImageLength >= MinLength && PartnerImageLength <= MaxLength &&
		  PartnerPileIndex != PileIndex;
#if	TRACE
		Log("%6d  %6d  %7d  %7d  %5.0f%%  %5.0f%%  %c\n",
		  PileIndex,
		  PartnerPileIndex,
		  PileLength,
		  PartnerPileLength,
		  (PartnerImageLength*100.0)/PileLength,
		  (PartnerImageLength*100.0)/PartnerPileLength,
		  IsGlobalImage ? 'Y' : 'N');
#endif
		if (IsGlobalImage)
			{
			PartnersRev[PartnerCount] = Image.SIRev;
			Partners[PartnerCount] = PartnerPileIndex;
			++PartnerCount;
			}
		}
	return PartnerCount;
	}

static void AddEdges(EdgeList &Edges, PILE_INDEX_TYPE PileIndex,
  PILE_INDEX_TYPE Partners[], bool PartnersRev[], int PartnerCount)
	{
	EdgeCount += PartnerCount;
	for (int i = 0; i < PartnerCount; ++i)
		{
		int PileIndex2 = Partners[i];
		EdgeData Edge;
		Edge.Node1 = PileIndex;
		Edge.Node2 = PileIndex2;
		Edge.Rev = PartnersRev[i];
		Edges.push_back(Edge);
		}
	}

static void FindGlobalEdges(EdgeList &Edges, int MaxImageCount)
	{
	Edges.clear();

	PILE_INDEX_TYPE *Partners = all(PILE_INDEX_TYPE, MaxImageCount);
	bool *PartnersRev = all(bool, MaxImageCount);
	for (int PileIndex = 0; PileIndex < PileCount; ++PileIndex)
		{
		PileData &Pile = Piles[PileIndex];
		int PartnerCount;
		if (g_paramSingleHitCoverage)
			PartnerCount = FindGlobalEdgesPileSingle(Pile, PileIndex, Partners, PartnersRev);
		else
			PartnerCount = FindGlobalEdgesPileMulti(Pile, PileIndex, Partners, PartnersRev);
		AddEdges(Edges, PileIndex, Partners, PartnersRev, PartnerCount);
		}
	freemem(Partners);
	freemem(PartnersRev);
	}

static void AssignFamsToPiles(FamList &Fams)
	{
	int FamIndex = 0;
	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamData *Fam = *p;
		for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
			{
			FamMemberData &FamMember = *q;
			int PileIndex = FamMember.PileIndex;
			PileData &Pile = Piles[PileIndex];
			Pile.FamIndex = FamIndex;
			Pile.Rev = (int) FamMember.Rev;
			}
		++FamIndex;
		}
	}

static inline unsigned TriangleSubscript(unsigned FamCount, unsigned i, unsigned j)
	{
	assert(i >= 0 && j >= 0 && i < FamCount && j < FamCount);
	unsigned v;
	if (i >= j)
		v = j + (i*(i - 1))/2;
	else
		v = i + (j*(j - 1))/2;
	assert(v < (FamCount*(FamCount - 1))/2);
	return v;
	}

static void FindSuperFamEdges(FamList &Fams, EdgeList &Edges)
	{
	const int FamCount = (int) Fams.size();

// Allocate triangular array Related[i][j], value is true
// iff families i and j are related (i.e., there is a local
// alignment between some member of i and some member of j).
	const int TriangleSize = (FamCount*(FamCount - 1))/2;
	bool *Related = all(bool, TriangleSize);
	zero(Related, bool, TriangleSize);
	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamData *Fam = *p;
		for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
			{
			FamMemberData &FamMember = *q;
			int PileIndex = FamMember.PileIndex;
			const PileData &Pile = Piles[PileIndex];
			const int FamIndex = Pile.FamIndex;
			if (-1 == FamIndex)
				continue;
			const int ImageCount = Pile.ImageCount;
			for (int ImageIndex = 0; ImageIndex < ImageCount; ++ImageIndex)
				{
				const PileImageData &Image = Pile.Images[ImageIndex];
				const int PartnerPileIndex = Image.SIPile;
				if (PartnerPileIndex == PileIndex)
					continue;
				const PileData &PartnerPile = Piles[PartnerPileIndex];
				const int PartnerFamIndex = PartnerPile.FamIndex;
				if (-1 == PartnerFamIndex || PartnerFamIndex == FamIndex)
					continue;
				const int Index = TriangleSubscript(FamCount, FamIndex, PartnerFamIndex);
				assert(Index >- 0 && Index < TriangleSize);
				Related[Index] = true;
				}
			}
		}

	Edges.clear();
	for (int i = 0; i < FamCount; ++i)
		for (int j = i + 1; j < FamCount; ++j)
			{
			const int Index = TriangleSubscript(FamCount, i, j);
			if (Related[Index])
				{
//				Log("R %d %d\n", i, j);
				EdgeData Edge;
				Edge.Node1 = i;
				Edge.Node2 = j;
				Edge.Rev = false;
				Edges.push_back(Edge);
				}
			}
	}

static void AssignSuperFamsToPiles(FamList &Fams, FamList &SuperFams)
	{
	const int FamCount = (int) Fams.size();
	FamData **FamVect = all(FamData *, FamCount);

	int FamIndex = 0;
	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamVect[FamIndex] = *p;
		++FamIndex;
		}

	int SuperFamIndex = 0;
	for (PtrFamList pSF = SuperFams.begin(); pSF != SuperFams.end(); ++pSF)
		{
		FamData &SFFams = *(*pSF);
		for (PtrFamData p = SFFams.begin(); p != SFFams.end(); ++p)
			{
			FamMemberData &FamMember = *p;
			int FamIndex = FamMember.PileIndex;
			assert(FamIndex >= 0 && FamIndex < FamCount);
			FamData *Fam = FamVect[FamIndex];
			for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
				{
				FamMemberData &FamMember = *q;
				int PileIndex = FamMember.PileIndex;
				assert(PileIndex >= 0 && PileIndex < PileCount);
				PileData &Pile = Piles[PileIndex];
				assert(Pile.FamIndex == FamIndex);
				Pile.SuperFamIndex = SuperFamIndex;
				}
			}
		++SuperFamIndex;
		}
	}

static void FindSingletonSuperFams(FamList &Fams, FamList &SuperFams)
	{
	const int FamCount = (int) Fams.size();
	FamData **FamVect = all(FamData *, FamCount);
	bool *FamAssigned = all(bool, FamCount);

	int FamIndex = 0;
	for (PtrFamList p = Fams.begin(); p != Fams.end(); ++p)
		{
		FamVect[FamIndex] = *p;
		FamAssigned[FamIndex] = false;
		++FamIndex;
		}

// Flag families that have been assigned to superfamilies superfamilies
	for (PtrFamList pSF = SuperFams.begin(); pSF != SuperFams.end(); ++pSF)
		{
		FamData &SFFams = *(*pSF);
		for (PtrFamData p = SFFams.begin(); p != SFFams.end(); ++p)
			{
			FamMemberData &FamMember = *p;
			int FamIndex = FamMember.PileIndex;
			assert(FamIndex >= 0 && FamIndex < FamCount);
			FamAssigned[FamIndex] = true;
			}
		}

// Create new superfamily for each unassigned family
	for (int FamIndex = 0; FamIndex < FamCount; ++FamIndex)
		{
		if (FamAssigned[FamIndex])
			continue;

		FamMemberData Fam;
		Fam.PileIndex = FamIndex;
		Fam.Rev = false;

		FamData *SuperFam = new FamData;
		SuperFam->push_back(Fam);

		SuperFams.push_back(SuperFam);
		}

// Validate
	int SuperFamIndex = 0;
	for (PtrFamList pSF = SuperFams.begin(); pSF != SuperFams.end(); ++pSF)
		{
		FamData &SFFams = *(*pSF);
		for (PtrFamData p = SFFams.begin(); p != SFFams.end(); ++p)
			{
			FamMemberData &FamMember = *p;
			int FamIndex = FamMember.PileIndex;
			assert(FamIndex >= 0 && FamIndex < FamCount);
			FamData *Fam = FamVect[FamIndex];

			for (PtrFamData q = Fam->begin(); q != Fam->end(); ++q)
				{
				FamMemberData &FamMember = *q;
				int PileIndex = FamMember.PileIndex;
				if (PileIndex == 5354)
					Log("");
				PileData &Pile = Piles[PileIndex];

				assert(Pile.FamIndex == FamIndex);
				}
			}
		++SuperFamIndex;
		}
	}

void TRS()
	{
	const char *InputFileName = RequiredValueOpt("trs");

	const char *OutputFileName = ValueOpt("out");
	const char *PilesFileName = ValueOpt("piles");
	const char *ImagesFileName = ValueOpt("images");

	const char *strMinFamSize = ValueOpt("famsize");
	const char *strMaxLengthDiffPct = ValueOpt("maxlengthdiffpct");
	g_paramSingleHitCoverage = !FlagOpt("multihit");

	if (0 == OutputFileName && 0 == PilesFileName && 0 == ImagesFileName)
		Quit("No output file specified, must be at least one of -out, -piles, -images");

	if (0 != strMinFamSize)
		g_paramMinFamSize = atoi(strMinFamSize);
	if (0 != strMaxLengthDiffPct)
		g_paramMaxLengthDiffPct = atoi(strMaxLengthDiffPct);

	Log("singlehit=%s famsize=%d maxlengthdiffpct=%d\n",
	  g_paramSingleHitCoverage ? "True" : "False",
	  g_paramMinFamSize,
	  g_paramMaxLengthDiffPct);

	ProgressStart("Read hit file");
	int HitCount;
	int SeqLength;
	HitData *Hits = ReadHits(InputFileName, &HitCount, &SeqLength);
	ProgressDone();

	Progress("%d hits", HitCount);

	SeqLengthChunks = (SeqLength + CHUNK_LENGTH - 1)/CHUNK_LENGTH;

	const int BitVectorLength = (SeqLengthChunks + BITS_PER_INT - 1)/BITS_PER_INT;
	int *CopyCount = all(int, BitVectorLength);
	zero(CopyCount, int, BitVectorLength);

	ProgressStart("Compute copy counts");
	for (int i = 0; i < HitCount; ++i)
		IncCopyCount(CopyCount, Hits[i]);
	ProgressDone();

	ProgressStart("Identify piles");
	PILE_INDEX_TYPE *PileIndexes = IdentifyPiles(CopyCount);
	ProgressDone();

	Progress("%d stacks", PileCount);

	freemem(CopyCount);
	CopyCount = 0;

	CreatePiles(Hits, HitCount, PileIndexes);

	if (0 != ImagesFileName)
		{
		ProgressStart("Writing images file");
		WriteImages(ImagesFileName, Hits, HitCount, PileIndexes);
		ProgressDone();
		}

	freemem(Hits);
	Hits = 0;

	if (0 != PilesFileName)
		{
		ProgressStart("Writing piles file");
		WritePiles(PilesFileName, Piles, PileCount);
		ProgressDone();
		}

	freemem(PileIndexes);
	PileIndexes = 0;

	if (0 == OutputFileName)
		return;

	ProgressStart("Find edges");
	EdgeList Edges;
	FindGlobalEdges(Edges, MaxImageCount);
	ProgressDone();

	Progress("%d edges", (int) Edges.size());

	ProgressStart("Find families");
	FamList Fams;
	FindConnectedComponents(Edges, Fams, g_paramMinFamSize);
	AssignFamsToPiles(Fams);
	ProgressDone();

	Progress("%d families", (int) Fams.size());

	ProgressStart("Find superfamilies");
	EdgeList SuperEdges;
	FindSuperFamEdges(Fams, SuperEdges);

	FamList SuperFams;
	FindConnectedComponents(SuperEdges, SuperFams, 1);
	FindSingletonSuperFams(Fams, SuperFams);

	AssignSuperFamsToPiles(Fams, SuperFams);
	ProgressDone();

	Progress("%d superfamilies", (int) SuperFams.size());

	ProgressStart("Write TRS output file");
	WriteTRSFile(OutputFileName, Piles, PileCount);
	ProgressDone();
	}
