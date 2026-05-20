#ifndef RND_H
#define RND_H

#include <stdint.h>
#include "v6c_rt_macros.h"

/*
 * ------------------------------------------------------------------
 * rnd — 16-bit xorshift pseudorandom number generator.
 * http://www.retroprogramming.com/2017/07/xorshift-pseudorandom-numbers-in-z80.html?m=1
 *
 * Output: HL, A = next pseudorandom value.
 *
 * Clobbers: A, FLAGS
 *
 * Algorithm: 3 xors and 2 shifts. ~20 bytes / 116cc.
 * Not a great generator by modern standards, but small and fast.
 * ------------------------------------------------------------------
*/
V6C_NOINLINE
uint16_t rnd(void)
{
    register uint16_t out_val asm("HL");
    __asm__ volatile (
"       1:                      \n\t"
"           lxi h, 1            \n\t" // seed must not be 0
"           mov a, h            \n\t"
"           rar                 \n\t"
"           mov a, l            \n\t"
"           rar                 \n\t"
"           xra h               \n\t"
"           mov h, a            \n\t"
"           mov a, l            \n\t"
"           rar                 \n\t"
"           mov a, h            \n\t"
"           rar                 \n\t"
"           xra l               \n\t"
"           mov l, a            \n\t"
"           xra h               \n\t"
"           mov h, a            \n\t"
"           shld 1b + 1         \n\t"
            : "=r"(out_val) :: "H", "L", "A", "FLAGS"
    );
    return out_val;
}


#endif /* RND_H */