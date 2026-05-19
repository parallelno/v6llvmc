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
 *   min() / max()               — embedded convenience macros
 */
#ifndef V6C_STDLIB_H_INCLUDED
#define V6C_STDLIB_H_INCLUDED

#ifndef __V6C__
#error "<stdlib.h> here is V6C-only; compile with -target i8080-unknown-v6c"
#endif

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

#ifdef __cplusplus
extern "C" {
#endif

static inline __attribute__((always_inline, __noreturn__))
void abort(void) {
    for (;;)
        __builtin_v6c_hlt();
}

static inline __attribute__((always_inline, __noreturn__))
void exit(int __status) {
    (void)__status;
    for (;;)
        __builtin_v6c_hlt();
}

#ifdef __cplusplus
}
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
