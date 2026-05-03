/* v6c_arith.h - Header-only V6C math runtime.
 *
 * Auto-included on -target i8080-unknown-v6c by the clang driver
 * (suppressible via -fno-v6c-auto-include). Defines every libcall
 * the V6C backend can emit (__mulqi3, __mulhi3, __udivhi3, __divhi3,
 * __umodhi3, __modhi3, __ashlhi3, __lshrhi3, __ashrhi3) plus a few
 * inline-only helpers.
 *
 * Linkage strategy
 * ----------------
 * Each routine is `static __attribute__((noinline, used))`:
 *   - static: per-TU local symbol; no multi-definition link errors.
 *   - noinline + used: guaranteed out-of-line copy in the .o so an
 *     ISel-emitted `CALL __mulqi3` (etc.) resolves to it via the
 *     assembler's same-TU symbol matching.
 *
 * IPRA recovers each routine's actual clobber set, so V6C's empty
 * getCallPreservedMask does not force callers to spill HL/DE/BC.
 *
 * Calling convention
 * ------------------
 * The function arguments use the V6C free-list C calling convention:
 *   i8  arg1 -> A   ; i8  arg2 -> B   ; i8  arg3 -> C ...
 *   i16 arg1 -> HL  ; i16 arg2 -> DE  ; i16 arg3 -> BC
 *   i16 return    -> HL
 *   i8  return    -> A
 * ISel's normal arg-placement code lines up with the bodies below,
 * so each routine's prologue is empty.
 *
 * Routine bodies are ports of compiler-rt/lib/builtins/v6c/...s.
 *
 * See design/plan_O70_math_header.md for the full design rationale
 * and the empirical RA finding that drove it.
 */
#ifndef V6C_ARITH_H_INCLUDED
#define V6C_ARITH_H_INCLUDED

#define V6C_RT static __attribute__((noinline, used, naked))

/* ------------------------------------------------------------------
 * __mulqi3 — 8x8 -> 8-bit multiply (low byte of product, in A).
 *
 * Inputs:  A = a (i8), B = b (i8)
 * Output:  A  = (a * b) & 0xFF   (matches LLVM's RTLIB::MUL_I8 contract)
 *          HL = full i16 product (side-effect; useful via __v6c_mulqihi3)
 * Clobbers: B (counter), C, D, E, H, L, FLAGS
 *
 * Algorithm: 8 iterations of shift-and-add. ~32 bytes / ~370 cycles
 * worst case. Compare to old `Promote i8 -> __mulhi3` which ran
 * 16 iterations (~720 cycles). ~2x faster for any i8 multiply.
 * ------------------------------------------------------------------ */
V6C_RT unsigned char __mulqi3(unsigned char a, unsigned char b) {

    __asm__ volatile (
        "MOV  E, B           \n\t"   /* E = b (multiplicand low) */
        "MVI  D, 0           \n\t"   /* D = 0 (multiplicand high) */
        "LXI  H, 0           \n\t"   /* HL = 0 (result) */
        "MVI  B, 8           \n"     /* loop counter */
        "1:                  \n\t"
        "DAD  H              \n\t"   /* result <<= 1 */
        "RLC                 \n\t"   /* A <<= 1, MSB -> CY */
        "JNC  2f             \n\t"
        "DAD  D              \n"     /* result += zext(b) */
        "2:                  \n\t"
        "DCR  B              \n\t"
        "JNZ  1b             \n\t"
        "MOV  A, L           \n\t"   /* return low byte in A */
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __v6c_mulqihi3 — explicit i8*i8 -> i16 widening multiply.
 *
 * Inputs:  A = a (u8), B = b (u8)
 * Output:  HL = a * b (full i16 product)
 * Clobbers: A, B (counter), C, D, E, FLAGS
 *
 * Same body as __mulqi3, but skips the closing MOV A, L so HL is
 * the documented return path. Useful when you want the full i16.
 * ------------------------------------------------------------------ */
V6C_RT unsigned __v6c_mulqihi3(unsigned char a, unsigned char b) {

    __asm__ volatile (
        "MOV  E, B           \n\t"
        "MVI  D, 0           \n\t"
        "LXI  H, 0           \n\t"
        "MVI  B, 8           \n"
        "1:                  \n\t"
        "DAD  H              \n\t"
        "RLC                 \n\t"
        "JNC  2f             \n\t"
        "DAD  D              \n"
        "2:                  \n\t"
        "DCR  B              \n\t"
        "JNZ  1b             \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __mulhi3 — 16x16 -> 16-bit unsigned multiply (low 16 bits).
 *
 * Inputs:  HL = a, DE = b
 * Output:  HL = (a * b) & 0xFFFF
 * Clobbers: A, B (counter), C, D, E, FLAGS
 *
 * Algorithm: two passes of 8 shift-add iterations (high then low byte
 * of the multiplier). ~50 bytes / ~1280 cycles worst case.
 * ------------------------------------------------------------------ */
V6C_RT unsigned __mulhi3(unsigned a, unsigned b) {

    __asm__ volatile (
        "XCHG                \n\t"   /* DE = a (mcand), HL = b (mplier) */
        "MOV  A, H           \n\t"   /* A = mplier high byte */
        "MOV  C, L           \n\t"   /* C = mplier low byte (saved) */
        "LXI  H, 0           \n\t"   /* HL = 0 (result) */
        "MVI  B, 8           \n"
        "1:                  \n\t"   /* pass 1: high byte */
        "DAD  H              \n\t"
        "RLC                 \n\t"
        "JNC  2f             \n\t"
        "DAD  D              \n"
        "2:                  \n\t"
        "DCR  B              \n\t"
        "JNZ  1b             \n\t"
        "MOV  A, C           \n\t"   /* A = mplier low byte */
        "MVI  B, 8           \n"
        "3:                  \n\t"   /* pass 2: low byte */
        "DAD  H              \n\t"
        "RLC                 \n\t"
        "JNC  4f             \n\t"
        "DAD  D              \n"
        "4:                  \n\t"
        "DCR  B              \n\t"
        "JNZ  3b             \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __v6c_udivmod16_body — internal divmod kernel.
 *
 * Inputs:  HL = dividend, DE = divisor
 * Output:  HL = quotient, BC = remainder
 * Clobbers: A, FLAGS, plus stack (PUSH/POP PSW for counter)
 *
 * Division by zero: returns HL=0xFFFF, BC=0 (matches the .s ref).
 *
 * Both __udivhi3 and __umodhi3 below tail into this body.
 * ------------------------------------------------------------------ */
V6C_RT void __v6c_udivmod16_body(void) {
    __asm__ volatile (
        /* divide-by-zero check */
        "MOV  A, D           \n\t"
        "ORA  E              \n\t"
        "JNZ  1f             \n\t"
        "LXI  H, 0xFFFF      \n\t"
        "LXI  B, 0           \n\t"
        "RET                 \n"
        "1:                  \n\t"
        "LXI  B, 0           \n\t"   /* remainder = 0 */
        "MVI  A, 16          \n\t"
        "PUSH PSW            \n"     /* save counter */
        "2:                  \n\t"   /* loop */
        "DAD  H              \n\t"   /* HL <<= 1 (quotient bit comes in at LSB=0) */
        "MOV  A, C           \n\t"
        "RAL                 \n\t"   /* C <<= 1, in = bit shifted out of HL */
        "MOV  C, A           \n\t"
        "MOV  A, B           \n\t"
        "RAL                 \n\t"
        "MOV  B, A           \n\t"
        /* Trial subtraction: BC - DE */
        "MOV  A, C           \n\t"
        "SUB  E              \n\t"
        "MOV  A, B           \n\t"
        "SBB  D              \n\t"
        "JC   3f             \n\t"   /* borrow -> remainder < divisor, skip */
        /* Commit subtraction and set quotient bit */
        "MOV  A, C           \n\t"
        "SUB  E              \n\t"
        "MOV  C, A           \n\t"
        "MOV  A, B           \n\t"
        "SBB  D              \n\t"
        "MOV  B, A           \n\t"
        "INX  H              \n"     /* set quotient LSB */
        "3:                  \n\t"
        "POP  PSW            \n\t"
        "DCR  A              \n\t"
        "PUSH PSW            \n\t"
        "JNZ  2b             \n\t"
        "POP  PSW            \n\t"   /* discard counter */
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __udivhi3 — unsigned 16-bit division. HL=a/b
 * Inputs:  HL = dividend, DE = divisor
 * Output:  HL = quotient
 * ------------------------------------------------------------------ */
V6C_RT unsigned __udivhi3(unsigned a, unsigned b) {

    __asm__ volatile (
        "CALL __v6c_udivmod16_body \n\t"
        "RET                       \n\t"
    );
}

/* ------------------------------------------------------------------
 * __umodhi3 — unsigned 16-bit modulo. HL=a%b
 * Inputs:  HL = dividend, DE = divisor
 * Output:  HL = remainder
 * ------------------------------------------------------------------ */
V6C_RT unsigned __umodhi3(unsigned a, unsigned b) {

    __asm__ volatile (
        "CALL __v6c_udivmod16_body \n\t"
        "MOV  H, B                 \n\t"
        "MOV  L, C                 \n\t"
        "RET                       \n\t"
    );
}

/* ------------------------------------------------------------------
 * __udivmodhi4 — fused unsigned 16-bit divmod (libgcc-compatible).
 *
 * Inputs:  HL = dividend, DE = divisor, BC = *rem (out-pointer)
 * Output:  HL = quotient, *(BC) = remainder (low byte first)
 * Clobbers: A, BC, DE, FLAGS, stack (PSW save in body)
 *
 * Bound to RTLIB::UDIVREM_I16 — when source has both `q=a/b` and
 * `r=a%b` of identical operands, ISel fuses to ONE call here instead
 * of two separate __udivhi3 + __umodhi3 calls.
 * ------------------------------------------------------------------ */
V6C_RT unsigned __udivmodhi4(unsigned a, unsigned b, unsigned *rem) {

    __asm__ volatile (
        "PUSH B                    \n\t"   /* save *rem pointer */
        "CALL __v6c_udivmod16_body \n\t"   /* HL=q, BC=r */
        "XTHL                      \n\t"   /* HL=ptr, top=q */
        "MOV  M, C                 \n\t"   /* *(ptr+0) = r low */
        "INX  H                    \n\t"
        "MOV  M, B                 \n\t"   /* *(ptr+1) = r high */
        "POP  H                    \n\t"   /* HL = quotient */
        "RET                       \n\t"
    );
}

/* ------------------------------------------------------------------
 * __divmodhi4 — fused signed 16-bit divmod (libgcc-compatible).
 *
 * Inputs:  HL = dividend, DE = divisor, BC = *rem (out-pointer)
 * Output:  HL = quotient (truncated toward zero),
 *          *(BC) = remainder (sign of dividend, C99/C11)
 *
 * Bound to RTLIB::SDIVREM_I16 — fuses signed div+mod of same operands.
 * ------------------------------------------------------------------ */
V6C_RT int __divmodhi4(int a, int b, int *rem) {

    __asm__ volatile (
        "PUSH B                     \n\t"   /* save *rem pointer */
        "MOV  A, H                  \n\t"
        "PUSH PSW                   \n\t"   /* save dividend sign byte */
        "MOV  A, H                  \n\t"
        "XRA  D                     \n\t"
        "PUSH PSW                   \n\t"   /* save quotient-sign byte (XOR) */
        "MOV  A, H                  \n\t"
        "ORA  A                     \n\t"
        "JP   1f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "1:                         \n\t"
        "MOV  A, D                  \n\t"
        "ORA  A                     \n\t"
        "JP   2f                    \n\t"
        "CALL __v6c_neg_de_body     \n"
        "2:                         \n\t"
        "CALL __v6c_udivmod16_body  \n\t"   /* HL=|q|, BC=|r| */
        /* Apply quotient sign */
        "POP  PSW                   \n\t"
        "ORA  A                     \n\t"
        "JP   3f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "3:                         \n\t"
        /* Apply remainder sign (sign of original dividend) */
        "POP  PSW                   \n\t"
        "ORA  A                     \n\t"
        "JP   4f                    \n\t"
        /* Negate BC: BC = -BC */
        "MOV  A, C                  \n\t"
        "CMA                        \n\t"
        "MOV  C, A                  \n\t"
        "MOV  A, B                  \n\t"
        "CMA                        \n\t"
        "MOV  B, A                  \n\t"
        "INX  B                     \n"
        "4:                         \n\t"
        "XTHL                       \n\t"   /* HL=ptr, top=q */
        "MOV  M, C                  \n\t"
        "INX  H                     \n\t"
        "MOV  M, B                  \n\t"
        "POP  H                     \n\t"   /* HL = signed quotient */
        "RET                        \n\t"
    );
}

/* ------------------------------------------------------------------
 * __v6c_neg_hl_body — negate HL (two's complement). Internal helper.
 * Clobbers: A, FLAGS.
 * ------------------------------------------------------------------ */
V6C_RT void __v6c_neg_hl_body(void) {
    __asm__ volatile (
        "MOV  A, L           \n\t"
        "CMA                 \n\t"
        "MOV  L, A           \n\t"
        "MOV  A, H           \n\t"
        "CMA                 \n\t"
        "MOV  H, A           \n\t"
        "INX  H              \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __v6c_neg_de_body — negate DE (two's complement). Internal helper.
 * Clobbers: A, FLAGS.
 * ------------------------------------------------------------------ */
V6C_RT void __v6c_neg_de_body(void) {
    __asm__ volatile (
        "MOV  A, E           \n\t"
        "CMA                 \n\t"
        "MOV  E, A           \n\t"
        "MOV  A, D           \n\t"
        "CMA                 \n\t"
        "MOV  D, A           \n\t"
        "INX  D              \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __divhi3 — signed 16-bit division. HL=a/b (truncated toward zero)
 * Inputs:  HL = dividend, DE = divisor
 * Output:  HL = quotient
 * ------------------------------------------------------------------ */
V6C_RT int __divhi3(int a, int b) {

    __asm__ volatile (
        "MOV  A, H                  \n\t"
        "XRA  D                     \n\t"   /* result sign: XOR of input signs */
        "PUSH PSW                   \n\t"
        "MOV  A, H                  \n\t"
        "ORA  A                     \n\t"
        "JP   1f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "1:                         \n\t"
        "MOV  A, D                  \n\t"
        "ORA  A                     \n\t"
        "JP   2f                    \n\t"
        "CALL __v6c_neg_de_body     \n"
        "2:                         \n\t"
        "CALL __v6c_udivmod16_body  \n\t"
        "POP  PSW                   \n\t"
        "ORA  A                     \n\t"
        "JP   3f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "3:                         \n\t"
        "RET                        \n\t"
    );
}

/* ------------------------------------------------------------------
 * __modhi3 — signed 16-bit modulo. C99/C11 truncated division
 *            (remainder has dividend's sign).
 * Inputs:  HL = dividend, DE = divisor
 * Output:  HL = remainder
 * ------------------------------------------------------------------ */
V6C_RT int __modhi3(int a, int b) {

    __asm__ volatile (
        "MOV  A, H                  \n\t"
        "PUSH PSW                   \n\t"   /* save dividend sign */
        "ORA  A                     \n\t"
        "JP   1f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "1:                         \n\t"
        "MOV  A, D                  \n\t"
        "ORA  A                     \n\t"
        "JP   2f                    \n\t"
        "CALL __v6c_neg_de_body     \n"
        "2:                         \n\t"
        "CALL __v6c_udivmod16_body  \n\t"
        "MOV  H, B                  \n\t"
        "MOV  L, C                  \n\t"
        "POP  PSW                   \n\t"
        "ORA  A                     \n\t"
        "JP   3f                    \n\t"
        "CALL __v6c_neg_hl_body     \n"
        "3:                         \n\t"
        "RET                        \n\t"
    );
}

/* ------------------------------------------------------------------
 * __ashlhi3 — variable left shift (HL <<= E)
 * Inputs:  HL = value, E = count (only low 4 bits used)
 * Output:  HL
 * Counts >=16 produce 0.
 * ------------------------------------------------------------------ */
V6C_RT unsigned __ashlhi3(unsigned a, unsigned char n) {

    __asm__ volatile (
        "MOV  A, E           \n\t"
        "ANI  0x0F           \n\t"
        "JZ   2f             \n\t"
        "CPI  16             \n\t"
        "JNC  3f             \n\t"
        "MOV  E, A           \n"
        "1:                  \n\t"
        "DAD  H              \n\t"
        "DCR  E              \n\t"
        "JNZ  1b             \n"
        "2:                  \n\t"
        "RET                 \n"
        "3:                  \n\t"
        "LXI  H, 0           \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __lshrhi3 — variable logical right shift (HL >>= E)
 * Inputs:  HL = value, E = count
 * Output:  HL
 * ------------------------------------------------------------------ */
V6C_RT unsigned __lshrhi3(unsigned a, unsigned char n) {

    __asm__ volatile (
        "MOV  A, E           \n\t"
        "ANI  0x0F           \n\t"
        "JZ   2f             \n\t"
        "CPI  16             \n\t"
        "JNC  3f             \n\t"
        "MOV  E, A           \n"
        "1:                  \n\t"
        "ORA  A              \n\t"   /* clear carry */
        "MOV  A, H           \n\t"
        "RAR                 \n\t"
        "MOV  H, A           \n\t"
        "MOV  A, L           \n\t"
        "RAR                 \n\t"
        "MOV  L, A           \n\t"
        "DCR  E              \n\t"
        "JNZ  1b             \n"
        "2:                  \n\t"
        "RET                 \n"
        "3:                  \n\t"
        "LXI  H, 0           \n\t"
        "RET                 \n\t"
    );
}

/* ------------------------------------------------------------------
 * __ashrhi3 — variable arithmetic right shift (HL >>= E, sign-fill)
 * Inputs:  HL = value, E = count
 * Output:  HL
 * ------------------------------------------------------------------ */
V6C_RT int __ashrhi3(int a, unsigned char n) {

    __asm__ volatile (
        "MOV  A, E           \n\t"
        "ANI  0x0F           \n\t"
        "JZ   2f             \n\t"
        "CPI  16             \n\t"
        "JNC  3f             \n\t"
        "MOV  E, A           \n"
        "1:                  \n\t"
        "MOV  A, H           \n\t"
        "RAL                 \n\t"   /* sign bit -> CY */
        "MOV  A, H           \n\t"
        "RAR                 \n\t"   /* CY -> bit 7 of H, bit 0 of H -> CY */
        "MOV  H, A           \n\t"
        "MOV  A, L           \n\t"
        "RAR                 \n\t"
        "MOV  L, A           \n\t"
        "DCR  E              \n\t"
        "JNZ  1b             \n"
        "2:                  \n\t"
        "RET                 \n"
        "3:                  \n\t"   /* count >= 16: sign-fill */
        "MOV  A, H           \n\t"
        "RAL                 \n\t"
        "SBB  A              \n\t"   /* A = -1 if sign=1, else 0 */
        "MOV  H, A           \n\t"
        "MOV  L, A           \n\t"
        "RET                 \n\t"
    );
}

#undef V6C_RT
#endif /* V6C_ARITH_H_INCLUDED */
