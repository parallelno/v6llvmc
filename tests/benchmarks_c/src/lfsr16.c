/* lfsr16 - 16-bit Galois LFSR (polynomial 0xB400, maximal-length over
 * GF(2)^16 — period 65535). Stresses i16 shift, conditional XOR with a
 * 16-bit constant, and i16 register pressure.
 *
 * The hot loop is:
 *   lsb  = lfsr & 1
 *   lfsr = lfsr >> 1
 *   if (lsb) lfsr ^= 0xB400
 *   acc ^= lfsr
 *
 * Initial seed 0xACE1; checksum is acc^(acc>>8) after ITERS steps.
 * ITERS chosen so all three compilers fit in the cycle cap.
 */
#include "bench.h"

#ifndef ITERS
#define ITERS 4096
#endif

int main(int argc, char **argv) {
    (void)argc; (void)argv;

    /* Volatile seed defeats constant-folding of the whole loop. */
    volatile u16 init = 0xACE1;
    u16 lfsr = init;
    u16 acc = 0;
    u16 i;

    for (i = 0; i < ITERS; i++) {
        u8 lsb = (u8)(lfsr & 1);
        lfsr = (u16)(lfsr >> 1);
        if (lsb) lfsr = (u16)(lfsr ^ 0xB400);
        acc = (u16)(acc ^ lfsr);
    }

    bench_finish((u8)((u8)acc ^ (u8)(acc >> 8)));
    return 0;
}
