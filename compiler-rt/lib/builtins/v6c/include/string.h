/* string.h - Header-only V6C `<string.h>` runtime.
 *
 * Provides the standard `mem*` / `str*` routines needed by V6C code.
 * Unlike `v6c_arith.h`, this header is NOT auto-included by the
 * clang driver — TUs that need these routines must
 * `#include <string.h>` explicitly.
 *
 * Linkage strategy is identical to `v6c_arith.h`: every routine is
 * `static naked noinline used annotate("v6c-rt-helper")` via the
 * shared `V6C_RT` macro. See `v6c_rt_macros.h` for the rationale.
 *
 * Calling convention (V6C default C CC):
 *   i16 arg1  -> HL   ; i16 arg2 -> DE   ; i16 arg3 -> BC
 *   i16 ret   -> HL   ; i8  ret  -> A
 *
 *   memcpy(dst, src, n)    : HL=dst,  DE=src, BC=n        -> HL=dst
 *   memset(dst, val, n)    : HL=dst,  DE=val, BC=n (E=lo) -> HL=dst
 *   memmove(dst, src, n)   : HL=dst,  DE=src, BC=n        -> HL=dst
 *   strlen(s)              : HL=s                         -> HL=len
 *   strcmp(a, b)           : HL=a,    DE=b                -> HL=int
 *   strcpy(dst, src)       : HL=dst,  DE=src              -> HL=dst
 *
 * Each routine is `naked`, so the body emits its own `RET`. Routines
 * use numeric labels (`1:`, `2:`, ...) so multiple per-TU copies do
 * not collide; numeric labels are scoped to each inline-asm region.
 *
 * Routine bodies for memcpy/memset/memmove are direct ports of the
 * old (unbuilt) `compiler-rt/lib/builtins/v6c/memory.s`. strlen,
 * strcmp, strcpy are new in O80.
 *
 * See design/plan_O80_string_header.md for the design rationale.
 */
#ifndef V6C_STRING_H_INCLUDED
#define V6C_STRING_H_INCLUDED

#ifndef __V6C__
#error "<string.h> here is V6C-only; compile with -target i8080-unknown-v6c"
#endif

#include <stddef.h>

#include "v6c_rt_macros.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ------------------------------------------------------------------
 * memcpy(dst, src, n) — copy n bytes from src to dst (non-overlapping).
 *
 * Inputs:  HL = dst, DE = src, BC = n
 * Output:  HL = dst (unchanged)
 * Clobbers: A, B, C, D, E, FLAGS
 * ------------------------------------------------------------------ */
V6C_RT void *memcpy(void *dst, const void *src, size_t n) {
    __asm__ volatile (
        "PUSH H              \n"     /* save dst for return */
        "1:                  \n\t"
        "MOV  A, B           \n\t"
        "ORA  C              \n\t"
        "JZ   2f             \n\t"   /* n == 0? */
        "LDAX D              \n\t"   /* A = *src */
        "MOV  M, A           \n\t"   /* *dst = A */
        "INX  H              \n\t"
        "INX  D              \n\t"
        "DCX  B              \n\t"
        "JMP  1b             \n"
        "2:                  \n\t"
        "POP  H              \n\t"   /* HL = original dst */
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * memset(dst, val, n) — fill n bytes at dst with low byte of val.
 *
 * Inputs:  HL = dst, DE = val (E = byte value, D ignored), BC = n
 * Output:  HL = dst (unchanged)
 * Clobbers: A, B, C, FLAGS
 *
 * Note: C requires only the low byte of `int val` to be used.
 * ------------------------------------------------------------------ */
V6C_RT void *memset(void *dst, int val, size_t n) {
    __asm__ volatile (
        "PUSH H              \n"
        "1:                  \n\t"
        "MOV  A, B           \n\t"
        "ORA  C              \n\t"
        "JZ   2f             \n\t"
        "MOV  M, E           \n\t"   /* *dst = (uint8_t)val */
        "INX  H              \n\t"
        "DCX  B              \n\t"
        "JMP  1b             \n"
        "2:                  \n\t"
        "POP  H              \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * memmove(dst, src, n) — copy n bytes; safe on overlapping ranges.
 *
 * Inputs:  HL = dst, DE = src, BC = n
 * Output:  HL = dst (unchanged)
 * Clobbers: A, B, C, D, E, FLAGS
 *
 * If dst < src: forward copy is safe (same as memcpy).
 * If dst >= src: copy backward starting from (dst+n-1, src+n-1).
 * ------------------------------------------------------------------ */
V6C_RT void *memmove(void *dst, const void *src, size_t n) {
    __asm__ volatile (
        "PUSH H              \n\t"   /* save dst for return */
        "MOV  A, B           \n\t"
        "ORA  C              \n\t"
        "JZ   5f             \n\t"   /* n == 0 → done */

        /* compare dst (HL) vs src (DE), set CY if HL < DE */
        "MOV  A, L           \n\t"
        "SUB  E              \n\t"
        "MOV  A, H           \n\t"
        "SBB  D              \n\t"
        "JC   3f             \n\t"   /* dst < src → forward */

        /* backward path: HL = dst+n-1, DE = src+n-1 */
        "DAD  B              \n\t"   /* HL = dst + n */
        "DCX  H              \n\t"   /* HL = dst + n - 1 */
        "PUSH H              \n\t"   /* save dst_end */
        "MOV  H, D           \n\t"
        "MOV  L, E           \n\t"   /* HL = src */
        "DAD  B              \n\t"   /* HL = src + n */
        "DCX  H              \n\t"   /* HL = src + n - 1 */
        "XCHG                \n\t"   /* DE = src_end */
        "POP  H              \n"     /* HL = dst_end */
        "2:                  \n\t"
        "MOV  A, B           \n\t"
        "ORA  C              \n\t"
        "JZ   5f             \n\t"
        "LDAX D              \n\t"
        "MOV  M, A           \n\t"
        "DCX  H              \n\t"
        "DCX  D              \n\t"
        "DCX  B              \n\t"
        "JMP  2b             \n"

        /* forward path: HL was clobbered by the compare; reload dst */
        "3:                  \n\t"
        "POP  H              \n\t"   /* restore original dst */
        "PUSH H              \n"     /* re-push for the final POP */
        "4:                  \n\t"
        "MOV  A, B           \n\t"
        "ORA  C              \n\t"
        "JZ   5f             \n\t"
        "LDAX D              \n\t"
        "MOV  M, A           \n\t"
        "INX  H              \n\t"
        "INX  D              \n\t"
        "DCX  B              \n\t"
        "JMP  4b             \n"
        "5:                  \n\t"
        "POP  H              \n\t"   /* HL = original dst */
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * strlen(s) — number of bytes before the terminating NUL.
 *
 * Inputs:  HL = s
 * Output:  HL = length
 * Clobbers: A, D, E, FLAGS
 * ------------------------------------------------------------------ */
V6C_RT size_t strlen(const char *s) {
    __asm__ volatile (
        "PUSH H              \n"     /* save start */
        "1:                  \n\t"
        "MOV  A, M           \n\t"
        "ORA  A              \n\t"
        "JZ   2f             \n\t"   /* found NUL */
        "INX  H              \n\t"
        "JMP  1b             \n"
        "2:                  \n\t"
        /* HL = &NUL; length = HL - start */
        "POP  D              \n\t"   /* DE = start */
        "MOV  A, L           \n\t"
        "SUB  E              \n\t"
        "MOV  L, A           \n\t"
        "MOV  A, H           \n\t"
        "SBB  D              \n\t"
        "MOV  H, A           \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * strcmp(a, b) — lexicographic compare as unsigned char sequences.
 *
 * Inputs:  HL = a, DE = b
 * Output:  HL = signed int: 0 if equal, negative if *a < *b at the
 *          first differing byte, positive if *a > *b.
 * Clobbers: A, C, D, E, FLAGS
 *
 * Implementation: byte-by-byte unsigned compare via `CMP M`. The
 * carry flag after `*b - *a` tells us the direction without ever
 * forming a difference byte that could lose its sign on overflow
 * (e.g., *a=0x80, *b=0x00 → unsigned: a>b, but byte diff 0x80
 * sign-extends to negative — wrong). Returning ±1 / 0 sidesteps it.
 * ------------------------------------------------------------------ */
V6C_RT int strcmp(const char *a, const char *b) {
    __asm__ volatile (
        "1:                  \n\t"
        "LDAX D              \n\t"   /* A = *b */
        "CMP  M              \n\t"   /* A - *a → flags; CY if *b < *a */
        "JNZ  2f             \n\t"   /* differ */
        /* equal byte; if it's NUL, strings are equal */
        "ORA  A              \n\t"   /* test A (still == *a == *b) */
        "JZ   4f             \n\t"
        "INX  H              \n\t"
        "INX  D              \n\t"
        "JMP  1b             \n"
        "2:                  \n\t"
        /* differ: CY set if *b < *a, i.e., *a > *b → return +1 */
        "JNC  3f             \n\t"
        "LXI  H, 1           \n\t"
        "RET                 \n"
        "3:                  \n\t"
        "LXI  H, 0xFFFF      \n\t"   /* *a < *b → return -1 */
        "RET                 \n"
        "4:                  \n\t"
        "LXI  H, 0           \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * strcpy(dst, src) — copy NUL-terminated string from src to dst.
 *
 * Inputs:  HL = dst, DE = src
 * Output:  HL = dst (unchanged)
 * Clobbers: A, D, E, FLAGS
 * ------------------------------------------------------------------ */
V6C_RT char *strcpy(char *dst, const char *src) {
    __asm__ volatile (
        "PUSH H              \n"     /* save dst */
        "1:                  \n\t"
        "LDAX D              \n\t"   /* A = *src */
        "MOV  M, A           \n\t"   /* *dst = A */
        "INX  H              \n\t"
        "INX  D              \n\t"
        "ORA  A              \n\t"   /* was the byte NUL? */
        "JNZ  1b             \n\t"
        "POP  H              \n\t"   /* HL = original dst */
        "RET                 \n\t"
    );
}

#ifdef __cplusplus
}
#endif

#undef V6C_RT

#endif /* V6C_STRING_H_INCLUDED */
