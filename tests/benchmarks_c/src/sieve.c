/* sieve - Sieve of Eratosthenes over [0..251]. OUT count of primes (=54).
 * Split into helpers so the v6c backend has shorter live ranges; flat
 * inlined version blew up regalloc on the i8080 GPR set. */
#include "bench.h"

#define N 252

#if defined(__V6C__) || defined(__GNUC__) || defined(__clang__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

static u8 buf[N];

static NOINLINE void init_buf(void) {
    u8 i;
    for (i = 0; i < N; i++) buf[i] = 1;
    buf[0] = 0;
    buf[1] = 0;
}

static NOINLINE void cross_off(u8 p) {
    /* Walk multiples of p starting at 2*p, using u16 index so codegen
     * stays simple (no overflow wrap to reason about). */
    u16 j;
    for (j = (u16)p + p; j < N; j = (u16)(j + p)) {
        buf[j] = 0;
    }
}

static NOINLINE u8 count_set(void) {
    u8 c = 0;
    u8 i;
    for (i = 0; i < N; i++) if (buf[i]) c = (u8)(c + 1);
    return c;
}

int main(int argc, char **argv) {
    (void)argc; (void)argv;
    u8 i;

    init_buf();
    for (i = 2; i < 16; i++) {
        if (buf[i]) cross_off(i);
    }
    bench_finish(count_set());
    return 0;
}
