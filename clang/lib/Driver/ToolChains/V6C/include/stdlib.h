/*===---- stdlib.h - V6C freestanding subset ------------------------------===
 *
 * V6C resource-dir <stdlib.h>. Bare-metal stub: abort() and exit() both
 * halt the CPU via __builtin_v6c_hlt(); status codes are discarded
 * because the V6C platform has no exit syscall.
 *
 * malloc/free are intentionally absent until a heap allocator is shipped.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_STDLIB_H
#define __V6C_STDLIB_H

#ifndef __V6C__
#error "<stdlib.h> from the V6C resource dir is V6C-specific"
#endif

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

static inline __attribute__((always_inline, noreturn))
void abort(void) {
    for (;;)
        __builtin_v6c_hlt();
}

static inline __attribute__((always_inline, noreturn))
void exit(int __status) {
    (void)__status;
    for (;;)
        __builtin_v6c_hlt();
}

#ifdef __cplusplus
}
#endif

#endif /* __V6C_STDLIB_H */
