/* v6c_arith.h - Inline-asm wrappers for V6C arithmetic builtins.
 *
 * Header-only replacement for the libgcc-style routines in
 * compiler-rt/lib/builtins/v6c/. Each wrapper is `static inline`
 * with a full asm body. Unlike a CALL to __mulhi3, the compiler
 * sees the exact clobber set (HL, DE, A, B, C, FLAGS) and can
 * keep any value in untouched regs alive across the multiply.
 *
 * Naming: GCC libgcc convention is __mulhi3 (16-bit), __mulqi3 (8-bit),
 * __divhi3, __udivhi3 ...  the suffix is GCC's machine-mode tag
 * (qi=8, hi=16, si=32) and the trailing 3 means 3-operand (dst + 2 src).
 *
 * Inputs are pinned to HL / DE via local register variables, which
 * works because clang/I8080 lists "HL", "DE", "BC" in getGCCRegNames.
 */
#ifndef V6C_ARITH_H
#define V6C_ARITH_H

/* 16x16 -> 16 unsigned multiply (low 16 bits of product).
 * Same shift-add algorithm as compiler-rt mulhi3.s but inlined.
 * Clobbers: A, B, C, FLAGS (HL = result, DE preserved as multiplicand).
 */
static inline unsigned __v6c_mulhi3(unsigned a, unsigned b) {
    register unsigned ha __asm__("HL") = a;   /* multiplicand */
    register unsigned hb __asm__("DE") = b;   /* multiplier */
    __asm__(
        "XCHG\n\t"               /* DE = mcand, HL = mplier */
        "MOV  A, H\n\t"
        "MOV  C, L\n\t"
        "LXI  H, 0\n\t"
        "MVI  B, 8\n"
        "1:\n\t"
        "DAD  H\n\t"             /* result <<= 1 */
        "RLC\n\t"
        "JNC  2f\n\t"
        "DAD  D\n"               /* result += mcand */
        "2:\n\t"
        "DCR  B\n\t"
        "JNZ  1b\n\t"
        "MOV  A, C\n\t"
        "MVI  B, 8\n"
        "3:\n\t"
        "DAD  H\n\t"
        "RLC\n\t"
        "JNC  4f\n\t"
        "DAD  D\n"
        "4:\n\t"
        "DCR  B\n\t"
        "JNZ  3b\n\t"
        : "+r"(ha)               /* HL: in = mcand, out = product */
        : "r"(hb)                /* DE: multiplier */
        : "A", "B", "C", "FLAGS"
    );
    return ha;
}

#endif /* V6C_ARITH_H */
