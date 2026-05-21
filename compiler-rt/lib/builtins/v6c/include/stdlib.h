/* stdlib.h - V6C <stdlib.h>.
 *
 * Single canonical <stdlib.h> for the V6C bare-metal target.
 * Provides the standard C subset that makes sense on a freestanding
 * i8080 target plus common embedded convenience macros.
 *
 * Contents:
 *   EXIT_SUCCESS / EXIT_FAILURE — standard exit codes
 *   abort() / exit()            — noreturn; both spin on HLT (no OS)
 *   abs() / labs()              — standard C integer absolute value
 *   RAND_MAX / rand() / srand() — 16-bit xorshift PRNG
 *   min() / max()               — embedded convenience macros
 */
#ifndef V6C_STDLIB_H_INCLUDED
#define V6C_STDLIB_H_INCLUDED

#ifndef __V6C__
#error "<stdlib.h> here is V6C-only; compile with -target i8080-unknown-v6c"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

V6C_INLINE_NORETURN
void abort(void) {
    for (;;)
        __builtin_v6c_hlt();
}

V6C_INLINE_NORETURN
void exit(uint8_t __status) {
    (void)__status;
    for (;;)
        __builtin_v6c_hlt();
}

#ifndef abs
#define abs(x)  ((x) < 0 ? -(x) : (x))
#endif

#ifndef labs
#define labs(x) ((long)(x) < 0 ? -(x) : (x))
#endif

#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif


/* -----------------------------------------------------------------------
 * PRNG — rand() / srand() / RAND_MAX
 *
 * 16-bit xorshift generator.
 * Reference: http://www.retroprogramming.com/2017/07/xorshift-pseudorandom-numbers-in-z80.html
 *
 * rand()  returns int in [0, RAND_MAX] (~22 bytes / ~120 cc per call).
 * srand() re-seeds the generator; seed 0 is clamped to 1 because
 * xorshift state must never be 0.
 *
 * State is file-scope static: each translation unit that includes
 * <stdlib.h> gets its own independent PRNG instance.  For typical
 * single-TU V6C programs this is identical to a global state.
 * ----------------------------------------------------------------------- */
#ifndef RAND_MAX
#define RAND_MAX 0xFFFF
#endif

/* Internal PRNG state — 16-bit, must not be 0. */
uint16_t __v6c_rand_state = 1u;

V6C_INLINE
void srand(uint16_t __seed) {
    __v6c_rand_state = __seed ? __seed : 1u;
}

/* rand() — xorshift16(7,9,8), result masked to [0, RAND_MAX]. */
V6C_NOINLINE
uint16_t rand(void) {
    register uint16_t __r asm("HL");
    __asm__ volatile (
    "1:  lhld   __v6c_rand_state    \n\t"
        "mov    a, h                \n\t"  /* --- seed ^= seed >> 9 --- */
        "rar                        \n\t"  /* A  = H >> 1  (CY = H.0)  */
        "mov    a, l                \n\t"
        "rar                        \n\t"  /* A  = L >> 1 | H.0 << 7  */
        "xra    h                   \n\t"
        "mov    h, a                \n\t"  /* H' = H ^ (seed>>9).hi    */
        "mov    a, l                \n\t"  /* --- seed ^= seed >> 1 (via RAR chain) --- */
        "rar                        \n\t"
        "mov    a, h                \n\t"
        "rar                        \n\t"
        "xra    l                   \n\t"
        "mov    l, a                \n\t"
        "xra    h                   \n\t"  /* --- seed ^= seed << 8 --- */
        "mov    h, a                \n\t"  /* H  = old-L ^ ...         */
        "shld   __v6c_rand_state    \n\t"  /* store updated state       */
        : "=r"(__r) :: "A", "FLAGS"
    );
    return (int)__r;
}

#endif /* V6C_STDLIB_H_INCLUDED */
