/* bsort - bubble-sort 255 i8 values, OUT sum-of-sorted. */
#include "bench.h"

#define N 255

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    u8 a[N];
    u8 i, j, t;

    /* Deterministic fill: 255 distinct bytes (gcd(31,256)=1). */
    for (i = 0; i < N; i++) {
        a[i] = (u8)(i * 31 + 7);
    }

    for (i = (u8)(N - 1); i != 0; i--) {
        for (j = 0; j < i; j++) {
            if (a[j] > a[j + 1]) {
                t = a[j];
                a[j] = a[j + 1];
                a[j + 1] = t;
            }
        }
    }

    u8 sum = 0;
    for (i = 0; i < N; i++) sum = (u8)(sum + a[i]);

    bench_finish(sum);
    return 0;
}
