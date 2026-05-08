/* fannkuch - port of the classic Anderson/Rettig benchmark, also
 * used by z88dk's benchmark suite (z88dk/wiki/Benchmarks#fannkuch).
 *
 * Generates every permutation of {0..N-1} in lexicographic order and
 * counts pancake flips: while perm[0] != 0, reverse the prefix
 * perm[0..perm[0]] and increment the flip counter. Reports the
 * maximum flip count over all permutations.
 *
 * The z88dk reference uses N=9 (~14 sec). We use N=7 (5040 perms,
 * known max-flips = 16) to keep all three compilers comfortably
 * inside the cycle cap. Volatile seed defeats constant folding.
 */
#include "bench.h"

#ifndef N
#define N 7
#endif

static u8 perm[N];
static u8 perm1[N];
static u8 count[N];

int main(int argc, char **argv) {
    (void)argc; (void)argv;

    volatile u8 seed = N;
    u8 n = seed;
    u8 i, k, r, flips, flips_max;
    u8 perm0;

    for (i = 0; i < n; i++) perm1[i] = i;
    r = n;
    flips_max = 0;

    for (;;) {
        while (r != 1) { count[r - 1] = r; r--; }

        for (i = 0; i < n; i++) perm[i] = perm1[i];
        flips = 0;
        while (perm[0] != 0) {
            k = perm[0];
            {
                u8 lo = 0;
                u8 hi = k;
                while (lo < hi) {
                    u8 tmp = perm[lo];
                    perm[lo] = perm[hi];
                    perm[hi] = tmp;
                    lo++;
                    hi--;
                }
            }
            flips++;
        }
        if (flips > flips_max) flips_max = flips;

        for (;;) {
            if (r == n) {
                bench_finish(flips_max);
                return 0;
            }
            perm0 = perm1[0];
            for (i = 0; i < r; i++) perm1[i] = perm1[i + 1];
            perm1[r] = perm0;
            count[r] = (u8)(count[r] - 1);
            if (count[r] > 0) break;
            r++;
        }
    }
}
