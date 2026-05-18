/* stdlib.h - Minimal V6C <stdlib.h> subset.
 *
 * Provides the integer absolute-value macros needed by V6C C code.
 * No dynamic allocation, no exit/abort — those require OS support
 * that the bare-metal V6C target does not have.
 *
 * Add entries here as the need arises.
 */
#ifndef V6C_STDLIB_H_INCLUDED
#define V6C_STDLIB_H_INCLUDED

#ifndef __V6C__
#error "<stdlib.h> here is V6C-only; compile with -target i8080-unknown-v6c"
#endif

#ifndef abs
#define abs(x)  ((x) < 0 ? -(x) : (x))
#endif

#ifndef labs
#define labs(x) ((x) < 0 ? -(x) : (x))
#endif

#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif

#endif /* V6C_STDLIB_H_INCLUDED */
