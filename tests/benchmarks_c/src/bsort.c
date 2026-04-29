/* bsort - bubble-sort 16 i8 values, OUT sum-of-sorted. */
#include "bench.h"

static const u8 INIT[16] = {
    13, 200, 7, 99, 42, 1, 250, 64,
    180, 17, 88, 33, 5, 222, 100, 155
};

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    u8 a[16];
    u8 i, j, t;

    for (i = 0; i < 16; i++) a[i] = INIT[i];

    for (i = 15; i != 0; i--) {
        for (j = 0; j < i; j++) {
            if (a[j] > a[j + 1]) {
                t = a[j];
                a[j] = a[j + 1];
                a[j + 1] = t;
            }
        }
    }

    u8 sum = 0;
    for (i = 0; i < 16; i++) sum = (u8)(sum + a[i]);

    bench_finish(sum);
    return 0;
}
