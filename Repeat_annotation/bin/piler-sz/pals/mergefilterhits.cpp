#include "pals.h"

const int MAXIGAP = 5;

static Trapezoid  *free_traps = NULL;
static Trapezoid eotrap;
static Trapezoid *eoterm = &eotrap;

static int HSORT(const void *l, const void *r)
	{ 
	FilterHit *x = (FilterHit *) l;
	FilterHit *y = (FilterHit *) r;
	return x->QFrom - y->QFrom;
	}

Trapezoid *MergeFilterHits(const char *SeqT, int SeqLengthT, const char *SeqQ,
  int SeqLengthQ, bool Self, const FilterHit *FilterHits, int FilterHitCount,
  const FilterParams &FP, int *ptrTrapCount)
{
	if (0 == FilterHitCount)
		{
		*ptrTrapCount = 0;
		return 0;
		}

	qsort((void *) FilterHits, FilterHitCount, sizeof(FilterHit), HSORT);

#if	DEBUG
	{
// Verify sort order
	for (int i = 0; i < FilterHitCount-1; ++i)
		if (FilterHits[i+1].QFrom < FilterHits[i].QFrom)
			Quit("Build_Trapezoids: not sorted");
	}
#endif
	const int TubeWidth = FP.TubeOffset + FP.SeedDiffs;
	const int DPADDING = 2;
	const int BINWIDE = TubeWidth - 1;
	const int BPADDING = k + 2;
	const int LPADDING = DPADDING + BINWIDE;

	free_traps = NULL;
	eoterm = &eotrap;

  Trapezoid *traporder, *traplist, *tailend;
  Trapezoid *b, *f, *t;
  int i, nd, tp;
  int trapcount;
#ifdef REPORT_SIZES
  int traparea;
#endif


#ifdef REPORT_SIZES
  traparea  = 0;
#endif


  eoterm->lft = SeqLengthQ+1+LPADDING;
  eoterm->rgt = SeqLengthQ+1;
  eoterm->bot = -1;
  eoterm->top = SeqLengthQ+1;
  eoterm->next = NULL;
  
  trapcount = 0;
  traporder = eoterm;
  traplist  = NULL;
  for (i = 0; i < FilterHitCount; i++)
    { nd = - FilterHits[i].DiagIndex;
	  if (Self && nd <= FP.SeedDiffs)
		  continue;
      tp =   FilterHits[i].QFrom - BPADDING;
#ifdef TEST_TRAP
      printf("  Diag %d [%d,%d]\n",
             nd,FilterHits[i].QFrom,FilterHits[i].QTo);
#endif
      f = NULL;
  // for b in traporder
      for (b = traporder; 1; b = t)
        { t = b->next;
          if (b->top < tp)
            { trapcount += 1;
#ifdef REPORT_SIZES
              traparea  += (b->top - b->bot + 1) * (b->rgt - b->lft + 1);
#endif
              if (f == NULL)
                traporder = t;
              else
                f->next = t;
              b->next = traplist;
              traplist = b;
            }
          else if (nd > b->rgt + DPADDING)
            f = b;
          else if (nd >= b->lft - LPADDING)
            { if (nd+BINWIDE > b->rgt)
                b->rgt = nd+BINWIDE;
              if (nd < b->lft)
                b->lft = nd;
              if (FilterHits[i].QTo > b->top)
                b->top = FilterHits[i].QTo;


              if (f != NULL && f->rgt + DPADDING >= b->lft)
                { f->rgt = b->rgt;
                  if (f->bot > b->bot) f->bot = b->bot;
                  if (f->top < b->top) f->top = b->top;
                  f->next = t;
                  b->next = free_traps;
                  free_traps = b;
                }
              else if (t != NULL && t->lft - DPADDING <= b->rgt)
                { b->rgt = t->rgt;
                  if (b->bot > t->bot) b->bot = t->bot;
                  if (b->top < t->top) b->top = t->top;
                  b->next = t->next;
                  t->next = free_traps;
                  free_traps = t;
                  t = b->next;
                  f = b;
                }
              else
                f = b;
              break;
            }
          else
            {
		// Add to free_trap list
			  if (free_traps == NULL)
                { free_traps = (Trapezoid *) malloc(sizeof(Trapezoid));
                  if (free_traps == NULL)
                    Quit("out of memory Trapezoid scan FilterHits");
                  free_traps->next = NULL;
                }
              if (f == NULL)
                f = traporder = free_traps;
              else
                f = f->next = free_traps;
              free_traps = f->next;
              f->next = b;
              f->top = FilterHits[i].QTo;
              f->bot = FilterHits[i].QFrom;
              f->lft = nd;
              f->rgt = f->lft + BINWIDE; 
              f = b;
              break;
            }
        }
#ifdef TEST_TRAP
      printf("  Blist:");
      for (b = traporder; b != NULL; b = b->next)
        printf(" [%d,%d]x[%d,%d]",
               b->bot,b->top,b->lft,b->rgt);
      printf("\n");
#endif
    }


  for (b = traporder; b != eoterm; b = t)
    { t = b->next;
      trapcount += 1;
#ifdef REPORT_SIZES
      traparea  += (b->top - b->bot + 1) * (b->rgt - b->lft + 1);
#endif
      b->next  = traplist;
      traplist = b;
    }


#ifdef REPORT_SIZES
  printf("\n  %9d trapezoids of area %d (%f%% of matrix)\n",
         trapcount,traparea,(100.*trapcount/SeqLengthT)/SeqLengthQ);
  fflush(stdout);
#endif


  { int lag, lst, lclip;
    int abot, atop;


#ifdef TEST_TRAPTRIM
    printf("SeqQ trimming:\n");
#endif
    for (b = traplist; b != NULL; b = b->next)
      { lag = (b->bot-MAXIGAP)+1;
        if (lag < 0) lag = 0;
        lst = b->top+MAXIGAP;
        if (lst > SeqLengthQ) lst = SeqLengthQ;


#ifdef TEST_TRAPTRIM
        printf("   [%d,%d]x[%d,%d] = %d\n",
               b->bot,b->top,b->lft,b->rgt,b->top - b->bot + 1);
#endif


        for (i = lag; i < lst; i++)
          { if (CharToLetter[(unsigned char) (SeqQ[i])] >= 0)
              { if (i-lag >= MAXIGAP)
                  { if (lag - b->bot > 0)
                      { if (free_traps == NULL)
                          { free_traps = (Trapezoid *) malloc(sizeof(Trapezoid));
                            if (free_traps == NULL)
                              Quit("out of memory Trapezoid cutter");
                            free_traps->next = NULL;
                          }
                        t = free_traps->next;
                        *free_traps = *b;
                        b->next = free_traps;
                        free_traps = t;
                        b->top = lag;
                        b = b->next;
                        b->bot = i;
                        trapcount += 1;
                      }
                    else
                      b->bot = i;
#ifdef TEST_TRAPTRIM
                    printf("  Cut trap SeqQ[%d,%d]\n",lag,i);
#endif
                  }
                lag = i+1;
              }
          }
        if (i-lag >= MAXIGAP)
          b->top = lag;
      }


#ifdef TEST_TRAPTRIM
    printf("SeqT trimming:\n");
#endif
    tailend = NULL;
    for (b = traplist; b != NULL; b = b->next)
      { if (b->top - b->bot < k) continue;


        abot = b->bot - b->rgt;
        atop = b->top - b->lft;


#ifdef TEST_TRAPTRIM
        printf("   [%d,%d]x[%d,%d] = %d\n",
               b->bot,b->top,b->lft,b->rgt,b->top - b->bot + 1);
#endif


        lag = (abot - MAXIGAP) + 1;
        if (lag < 0) lag = 0;
        lst = atop + MAXIGAP;
        if (lst > SeqLengthT) lst = SeqLengthT;


        lclip = abot;
        for (i = lag; i < lst; i++)
          { if (CharToLetter[(unsigned char) (SeqT[i])] >= 0)
              { if (i-lag >= MAXIGAP)
                  { if (lag > lclip)
                      { if (free_traps == NULL)
                          { free_traps = (Trapezoid *) malloc(sizeof(Trapezoid));
                            if (free_traps == NULL)
                              Quit("out of memory Trapezoid cutter");
                            free_traps->next = NULL;
                          }
                        t = free_traps->next;
                        *free_traps = *b;
                        b->next = free_traps;
                        free_traps = t;


#ifdef TEST_TRAPTRIM
                        printf("     Clip to %d,%d\n",lclip,lag);
#endif
                        { int x, m;
                          x = lclip + b->lft;
                          if (b->bot < x) 
                            b->bot = x;
                          x = lag + b->rgt;
                          if (b->top > x)
                            b->top = x;
                          m = (b->bot + b->top) / 2;
                          x = m - lag;
                          if (b->lft < x)
                            b->lft = x;
                          x = m - lclip;
                          if (b->rgt > x)
                            b->rgt = x;
#ifdef TEST_TRAPTRIM
                          printf("        [%d,%d]x[%d,%d] = %d\n",
                                 b->bot,b->top,b->lft,b->rgt,b->top-b->bot+1);
#endif
                        }


                        b = b->next;
                        trapcount += 1;
                      }
                    lclip = i;
                  }
                lag = i+1;
              }
          }


        if (i-lag < MAXIGAP)
          lag = atop;


#ifdef TEST_TRAPTRIM
        printf("     Clip to %d,%d\n",lclip,lag);
#endif
        { int x, m;
          x = lclip + b->lft;
          if (b->bot < x) 
            b->bot = x;
          x = lag + b->rgt;
          if (b->top > x)
            b->top = x;
          m = (b->bot + b->top) / 2;
          x = m - lag;
          if (b->lft < x)
            b->lft = x;
          x = m - lclip;
          if (b->rgt > x)
            b->rgt = x;
#ifdef TEST_TRAPTRIM
          printf("        [%d,%d]x[%d,%d] = %d\n",
                 b->bot,b->top,b->lft,b->rgt,b->top-b->bot+1);
#endif
        }


        tailend = b;
      }
  }


  if (tailend != NULL)
    { tailend->next = free_traps;
      free_traps = traplist;
    }


#ifdef REPORT_SIZES
  printf("  %9d trimmed trap.s of area %d (%f%% of matrix)\n",
         trapcount,traparea,(100.*trapcount/SeqLengthT)/SeqLengthQ);
  fflush(stdout);
#endif


  *ptrTrapCount = trapcount;
  return traplist;
}

int SumTrapLengths(const Trapezoid *Traps)
	{
	int Sum = 0;
	for (const Trapezoid *T = Traps; T; T = T->next)
		{
		const int Length = T->top - T->bot;
		Sum += Length;
		}
	return Sum;
	}
