#include "pals.h"
#include "forkmer.h"

void FreeIndex(int Finger[], int Pos[])
	{
	freemem(Finger);
	freemem(Pos);
	}

// Check that index is correct
void CheckIndex(char *S, int Slen, const int Finger[], const int Pos[])
	{
	int Found = 0;
	FOR_EACH_KMER(S, Slen, i, c)
		bool bFound = false;
		for (int j = Finger[c]; j < Finger[c+1]; ++j)
			{
			if (Pos[j] == i)
				{
				++Found;
				bFound = true;
				break;
				}
			}
		if (!bFound)
			Quit("CheckIndex failed");
	END_FOR_EACH_KMER(S, Slen, i, c)

	Log("CheckIndex OK, %u kmers found\n", Found);
	}

// MakeIndex: make kmer index into S.
// Index is two arrays Finger[] and Pos[].
// There is one entry in Finger for every possible kmer.
// Consider a kmer with code k. Let i = Finger[k] and
// j = Finger[k+1]. Then Pos[i], Pos[i+1] ... Pos[j-1] are
// the locations in S where k is found.
// If i = j, then the kmer is not present in S.
//		S				[in] string to be indexed
//		Slen			[in] number of letters in S
//		k				[in] kmer length
//		*ptrFinger		[out] Finger[]
//		*ptrPos			[out] Pos[]
void MakeIndex(char *S, int Slen, int **ptrFinger, int **ptrPos)
	{
	assert(k > 1);
	assert(Slen >= k);

// ctop = number of distinct kmers = (max c) + 1, where c is code.
	const int ctop = pow4(k);
	int *Finger = all(int, ctop + 1);
	zero(Finger, int, ctop + 1);
	
// KmersInS = number of kmers in S
	const int KmersInS = Slen - k + 1;
	int *Pos = all(int, KmersInS);

// Set Finger[c+1] to be Count[c] = number of times kmer with
// code c is found in S.
	int *TableBase = Finger + 1;
	FOR_EACH_KMER(S, Slen, i, c)
		++(TableBase[c]);
	END_FOR_EACH_KMER(S, Slen, i, c)

// Set Finger[c+1] = sum(i<c) Count[c]
	TableBase = Finger + 1;
	int Sum = 0;
	int Prev;
	for (int i = 0; i < ctop; ++i)
		{
		Prev = TableBase[i];
		TableBase[i] = Sum;
		Sum += Prev;
		}

// Set Pos[Lo..Hi] to locations of kmer in S, where
// Lo=Finger[c], Hi=Finger[c+1] - 1.
	FOR_EACH_KMER(S, Slen, i, c)
		Pos[(TableBase[c])++] = i;
	END_FOR_EACH_KMER(S, Slen, i, c)
	Finger[0] = 0;

	*ptrFinger = Finger;
	*ptrPos = Pos;
	}
