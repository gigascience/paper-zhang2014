#include "pals.h"

extern void Align_Recursion(char *A, int Alen, char *B, int Blen,
  Trapezoid *b, int current, int comp, int MinLen, double MaxDiff, int Traplen);
extern int TSORT(const void *l, const void *r);
extern int StSORT(const void *l, const void *r);
extern int FnSORT(const void *l, const void *r);

// shared with aligntraps.cpp
Trapezoid **Tarray = NULL;
int *Covered;
DPHit *SegSols = NULL;
int SegMax = -1;
int NumSegs;

static int fseg;
static int TarMax = -1;

DPHit *AlignTraps(char *A, int Alen, char *B, int Blen, Trapezoid *Traplist,
  int Traplen, int comp, const DPParams &DP, int *ptrSegCount)
{ 
	Tarray = NULL;
	Covered = 0;
	SegSols = NULL;
	SegMax = -1;
	fseg = 0;
	TarMax = -1;

  const int MinLen = DP.MinHitLength;
  const double MaxDiff = 1.0 - DP.MinId;

  Trapezoid *b;
  int i;


  if (Traplen >= TarMax)
    { TarMax = (int) (1.2*Traplen + 500);
      Tarray = (Trapezoid **)
               ckrealloc(Tarray,(sizeof(Trapezoid *) + sizeof(int))*TarMax,"Trapezoid array");
      Covered = (int *) (Tarray + TarMax);
    }
  if (SegMax < 0)
    { SegMax = 1000;
      SegSols = (DPHit *) ckalloc(sizeof(DPHit)*SegMax,"Segement alignment array");
    }


  i = 0;
  b = Traplist;
  for (i = 0; i < Traplen; i++)
    { Tarray[i] = b;
      Covered[i] = 0;
      b = b->next;
    }


  qsort(Tarray,Traplen,sizeof(Trapezoid *),TSORT);


#ifdef SHOW_TRAP
  { int i;
    Trapezoid *t;


    for (i = 0; i < Traplen; i++)             
      { t = Tarray[i];
        printf("  [%d,%d] x [%d,%d]\n",t->bot,t->top,t->lft,t->rgt);
      }
  }
#endif


#ifdef REPORT_DPREACH
  Al_depth = 0;
#endif
  NumSegs = 0;
  fseg = NumSegs;
  for (i = 0; i < Traplen; i++)
    if (! Covered[i])
      { b = Tarray[i];
        if (b->top - b->bot < k) continue;
        Align_Recursion(A,Alen,B,Blen,b,i,comp,MinLen,MaxDiff,Traplen);
      }


  /* Remove lower socring segments that begin or end at
       the same point as a higher scoring segment.       */


  if (NumSegs > fseg)
    { int i, j;


      qsort(SegSols+fseg,NumSegs-fseg,sizeof(DPHit),StSORT);
      for (i = fseg; i < NumSegs; i = j)
        { for (j = i+1; j < NumSegs; j++)
            { if (SegSols[j].abpos != SegSols[i].abpos) break;
              if (SegSols[j].bbpos != SegSols[i].bbpos) break;
              if (SegSols[j].score > SegSols[i].score)
                { SegSols[i].score = -1; i = j; }
              else
                SegSols[j].score = -1;
            }
        }


      qsort(SegSols+fseg,NumSegs-fseg,sizeof(DPHit),FnSORT);
      for (i = fseg; i < NumSegs; i = j)
        { for (j = i+1; j < NumSegs; j++)
            { if (SegSols[j].aepos != SegSols[i].aepos) break;
              if (SegSols[j].bepos != SegSols[i].bepos) break;
              if (SegSols[j].score > SegSols[i].score)
                { SegSols[i].score = -1; i = j; }
              else
                SegSols[j].score = -1;
            }
        }


      for (i = fseg; i < NumSegs; i++)
        if (SegSols[i].score >= 0)
          SegSols[fseg++] = SegSols[i];
      NumSegs = fseg;
    }


#ifdef REPORT_SIZES
  printf("\n  %9d segments\n",NumSegs);
  fflush(stdout);
#endif

  free(Tarray);
  Tarray = 0;

  *ptrSegCount = NumSegs;
  return SegSols;
}

int SumDPLengths(const DPHit *DPHits, int HitCount)
	{
	int Sum = 0;
	for (int i = 0; i < HitCount; ++i)
		{
		const DPHit &Hit = DPHits[i];
		const int Length = Hit.aepos - Hit.abpos;
		if (Length < 0)
			Quit("SumDPLengths, Length < 0");
		Sum += Length;
		}
	return Sum;
	}
