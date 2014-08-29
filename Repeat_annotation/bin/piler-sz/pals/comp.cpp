#include "pals.h"

void Complement(char *seq, int len)
{ static char WCinvert[256];
  static int Firstime = 1;
  if (Firstime)          /* Setup complementation array */
    { int i;


      Firstime = 0;
      for(i = 0; i < 256;i++){
        WCinvert[i] = '?';
      }
      WCinvert['a'] = 't';
      WCinvert['c'] = 'g';
      WCinvert['g'] = 'c';
      WCinvert['t'] = 'a';
      WCinvert['n'] = 'n';
      WCinvert['A'] = 'T';
      WCinvert['C'] = 'G';
      WCinvert['G'] = 'C';
      WCinvert['T'] = 'A';
      WCinvert['N'] = 'N';
      WCinvert['-'] = '-'; // added this to enable alignment of gapped consensi
    }


  /* Complement and reverse sequence */


  { register unsigned char *s, *t;
    int c;


    s = (unsigned char *) seq;
    t = (unsigned char *) (seq + (len-1));
    while (s < t)
      { c = *s;
        *s++ = WCinvert[(int) *t];
        *t-- = WCinvert[c];
      }
    if (s == t)
      *s = WCinvert[(int) *s];
  }
}
