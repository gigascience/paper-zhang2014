#ifndef bitfuncs_h
#define bitfuncs_h

static inline void SetBit(int *BitVec, int Bit)
	{
	int IntIndex = Bit/BITS_PER_INT;
	int BitIndex = Bit%BITS_PER_INT;
	int i = BitVec[IntIndex];
	BitVec[IntIndex] = (i | (1 << BitIndex));
	}

static inline int BitIsSet(int *BitVec, int Bit)
	{
	int IntIndex = Bit/BITS_PER_INT;
	int BitIndex = Bit%BITS_PER_INT;
	int i = BitVec[IntIndex];
	return (i & (1 << BitIndex));
	}

#endif // bitfuncs_h
