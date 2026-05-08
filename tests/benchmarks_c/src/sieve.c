/* sieve - Sieve of Eratosthenes, port of the z88dk benchmark
 * (z88dk/support/benchmarks/sieve/sdcc/sieve.c).
 *
 * Investigates numbers 2..SIZE-1 for primes using a flat byte array
 * of "is composite" flags. The hot inner loop crosses off multiples
 * of each prime starting at i_sq (i*i), advancing i_sq by 2*i+1 to
 * avoid a multiply.
 *
 * The reference reports `count` (number of primes), a u16. To fit the
 * one-byte bench_finish channel we XOR the high and low bytes; for
 * SIZE=8000 the count is 1007 (0x03EF) and the checksum is 0xEC.
 */
#include "bench.h"

#ifndef SIZE
#define SIZE 8000
#endif

static u8 flags[SIZE];

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    u16 i, i_sq, k, count;

    /* some compilers do not initialize properly */
    {
        u16 n;
        for (n = 0; n < SIZE; n++) flags[n] = 0;
    }

    count = SIZE - 2;

    i_sq = 4;
    for (i = 2; i_sq < SIZE; ++i) {
        if (!flags[i]) {
            for (k = i_sq; k < SIZE; k = (u16)(k + i)) {
                if (!flags[k]) count = (u16)(count - 1);
                flags[k] = 1;
            }
        }
        i_sq = (u16)(i_sq + i + i + 1);  /* (n+1)^2 = n^2 + 2n + 1 */
    }

    bench_finish((u8)((u8)count ^ (u8)(count >> 8)));
    return 0;
}
