/*===---- v6c.h - V6C target-specific intrinsic wrappers ------------------===
 *
 * Thin inline wrappers around the __builtin_v6c_* family. These map
 * directly onto i8080 instructions (IN, OUT, DI, EI, HLT, NOP) and are
 * always inlined; including this header has zero call overhead.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_H
#define __V6C_V6C_H

#ifndef __V6C__
#error "<v6c.h> is only valid for the V6C target"
#endif

#ifdef __cplusplus
extern "C" {
#endif

static inline __attribute__((always_inline))
unsigned char __v6c_in(unsigned char __port) {
    return __builtin_v6c_in(__port);
}

static inline __attribute__((always_inline))
void __v6c_out(unsigned char __port, unsigned char __val) {
    __builtin_v6c_out(__port, __val);
}

static inline __attribute__((always_inline))
void __v6c_di(void)  { __builtin_v6c_di(); }

static inline __attribute__((always_inline))
void __v6c_ei(void)  { __builtin_v6c_ei(); }

static inline __attribute__((always_inline, noreturn))
void __v6c_hlt(void) {
    for (;;)
        __builtin_v6c_hlt();
}

static inline __attribute__((always_inline))
void __v6c_nop(void) { __builtin_v6c_nop(); }

#ifdef __cplusplus
}
#endif

#endif /* __V6C_V6C_H */
