#define FOR_EACH_KMER(S, Slen, i, c)		\
	{										\
	const int Kmask = pow4(k) - 1;			\
	unsigned char *ptrS = (unsigned char *) S;					\
	unsigned char *ptrSEnd = (unsigned char *) (S + Slen - 1);	\
	int c = 0;								\
	int h = 0;								\
	for (int j = 0; j < k - 1; ++j)			\
		{									\
		int x = CharToLetter[*ptrS++];		\
		if (x >= 0)							\
			c = (c << 2) | x;				\
		else								\
			{								\
			c = 0;							\
			h = j + 1;						\
			}								\
		}									\
	int i = 0;								\
	for ( ; ptrS <= ptrSEnd; ++i)			\
		{									\
		int x = CharToLetter[*ptrS++];		\
		if (x >= 0)							\
			c = ((c << 2) | x) & Kmask;		\
		else								\
			{								\
			c = 0;							\
			h = i + k;						\
			}								\
		if (i >= h)							\
			{

#define	END_FOR_EACH_KMER(S, Slen, i, c)	\
			}								\
		}									\
	}
