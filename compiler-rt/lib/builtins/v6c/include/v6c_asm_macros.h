/*===---- v6c_macros.h - V6C i8080 inline-asm utility macros -------------===
 *
 * C preprocessor / inline-asm translation of v6_macros.asm.
 *
 * All macros that produce assembly code expand to inline-asm string
 * fragments — double-quoted, terminated with " \n\t" — suitable for
 * pasting directly into __asm__ volatile string bodies.  Each macro
 * is #ifndef-guarded so project code can override individual macros
 * before including this header.
 *
 * 'u'-suffix rule
 * ---------------
 * v6c_consts.h defines constants with the C 'u' suffix (e.g. 0x11u).
 * LLVM MC's integrated assembler does NOT accept the 'u' suffix, so
 * those constants must NOT appear in asm strings.  This header
 * provides '_V6C_*' shadow constants — identical numeric values but
 * WITHOUT the suffix — for use inside asm strings.  Use _V6C_XSTR()
 * to stringify them.
 *
 * When passing a 'mode' / 'cmd' argument to CALL_RAM_DISK_FUNC* or
 * RAM_DISK_ON*, the expression must expand to integer literals without
 * 'u' suffixes.  Use the _V6C_RAM_DISK_* shadows (defined below) and
 * define any project-specific constants without 'u':
 *
 *   #define MY_BANK_MODE  0x10          // no 'u' — asm-stringifiable
 *   CALL_RAM_DISK_FUNC_NO_RESTORE(my_fn, MY_BANK_MODE | _V6C_RAM_DISK_M_8F)
 *
 * Label macros
 * ------------
 * Macros that emit conditional branches (CLAMP_A, INR_CLAMP_M, …)
 * use the %=-suffix convention so each asm block gets unique labels.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_MACROS_H
#define __V6C_V6C_MACROS_H

#ifndef __V6C__
#error "<v6c_macros.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include <stdbool.h>
#include "v6c_consts.h"
#include <v6c_rt_macros.h>

/* ==========================================================================
 * Internal stringify helpers
 * ========================================================================== */
#ifndef _V6C_STR
#define _V6C_STR(x)  #x
#endif
#ifndef _V6C_XSTR
#define _V6C_XSTR(x) _V6C_STR(x)
#endif

/* ==========================================================================
 * Asm-safe shadow constants  (no 'u' suffix — LLVM MC compatible)
 * Values must stay in sync with v6c_consts.h.
 * ========================================================================== */
#define _V6C_RAM_DISK_PORT      0x11    /* = RAM_DISK1_PORT = RAM_DISK_PORT  */
#define _V6C_RAM_DISK_OFF_CMD   0       /* = RAM_DISK_OFF_CMD                */
#define _V6C_RAM_DISK_S0        0x10    /* = RAM_DISK_S0                     */
#define _V6C_RAM_DISK_S1        0x14    /* = RAM_DISK_S1                     */
#define _V6C_RAM_DISK_S2        0x18    /* = RAM_DISK_S2                     */
#define _V6C_RAM_DISK_S3        0x1C    /* = RAM_DISK_S3                     */
#define _V6C_RAM_DISK_M0        0x00    /* = RAM_DISK_M0                     */
#define _V6C_RAM_DISK_M1        0x01    /* = RAM_DISK_M1                     */
#define _V6C_RAM_DISK_M2        0x02    /* = RAM_DISK_M2                     */
#define _V6C_RAM_DISK_M3        0x03    /* = RAM_DISK_M3                     */
#define _V6C_RAM_DISK_M_89      0x40    /* = RAM_DISK_M_89                   */
#define _V6C_RAM_DISK_M_AD      0x20    /* = RAM_DISK_M_AD                   */
#define _V6C_RAM_DISK_M_EF      0x80    /* = RAM_DISK_M_EF                   */
#define _V6C_RAM_DISK_M_8F      (_V6C_RAM_DISK_M_89 | _V6C_RAM_DISK_M_AD | _V6C_RAM_DISK_M_EF)
#define _V6C_RAM_DISK_M_AF      (_V6C_RAM_DISK_M_AD | _V6C_RAM_DISK_M_EF)
#define _V6C_PORT0_OUT_OUT      0x88    /* = PORT0_OUT_OUT                   */
#define _V6C_INTS_PER_SEC       50      /* = INTS_PER_SEC                    */
#define _V6C_PALETTE_LEN        16      /* = PALETTE_LEN                     */

/* Internal asm-string-safe port literal used by RAM Disk macros. */
#define _V6C_RAM_DISK_PORT_S    _V6C_XSTR(_V6C_RAM_DISK_PORT)  /* "0x11" */

/* ==========================================================================
 * Instruction repetition helpers  (_V6C_REP1 … _V6C_REP8)
 *
 * _V6C_REP(n, s)  expands to n copies of asm string fragment s.
 * n must be a literal integer token in [1, 8].
 * ========================================================================== */
#define _V6C_REP1(s) s
#define _V6C_REP2(s) s s
#define _V6C_REP3(s) s s s
#define _V6C_REP4(s) s s s s
#define _V6C_REP5(s) s s s s s
#define _V6C_REP6(s) s s s s s s
#define _V6C_REP7(s) s s s s s s s
#define _V6C_REP8(s) s s s s s s s s
#define _V6C_REP(n, s) _V6C_REP##n(s)

/* ==========================================================================
 * Per-instruction loop macros
 * Emit i copies of the named instruction.  i must be a literal 1–8.
 * ========================================================================== */

#ifndef HLT_
#define HLT_(i)     _V6C_REP(i, "hlt \n\t")
#endif
#ifndef RRC_
#define RRC_(i)     _V6C_REP(i, "rrc \n\t")
#endif
#ifndef RAL_
#define RAL_(i)     _V6C_REP(i, "ral \n\t")
#endif
#ifndef RLC_
#define RLC_(i)     _V6C_REP(i, "rlc \n\t")
#endif
#ifndef PUSH_B
#define PUSH_B(i)   _V6C_REP(i, "push b \n\t")
#endif
#ifndef PUSH_H
#define PUSH_H(i)   _V6C_REP(i, "push h \n\t")
#endif
#ifndef POP_H
#define POP_H(i)    _V6C_REP(i, "pop h \n\t")
#endif
#ifndef INR_D
#define INR_D(i)    _V6C_REP(i, "inr d \n\t")
#endif
#ifndef INX_H
#define INX_H(i)    _V6C_REP(i, "inx h \n\t")
#endif
#ifndef INX_D
#define INX_D(i)    _V6C_REP(i, "inx d \n\t")
#endif
#ifndef DCX_H
#define DCX_H(i)    _V6C_REP(i, "dcx h \n\t")
#endif
#ifndef DCX_D
#define DCX_D(i)    _V6C_REP(i, "dcx d \n\t")
#endif
#ifndef DCR_M
#define DCR_M(i)    _V6C_REP(i, "dcr m \n\t")
#endif
#ifndef INR_L
#define INR_L(i)    _V6C_REP(i, "inr l \n\t")
#endif
#ifndef INR_H
#define INR_H(i)    _V6C_REP(i, "inr h \n\t")
#endif
#ifndef INR_M
#define INR_M(i)    _V6C_REP(i, "inr m \n\t")
#endif
#ifndef INR_A
#define INR_A(i)    _V6C_REP(i, "inr a \n\t")
#endif
#ifndef NOP_
#define NOP_(i)     _V6C_REP(i, "nop \n\t")
#endif
#ifndef ADD_A
#define ADD_A(i)    _V6C_REP(i, "add a \n\t")
#endif
#ifndef DAD_H
#define DAD_H(i)    _V6C_REP(i, "dad h \n\t")
#endif

/* ==========================================================================
 * Signed LXI helpers
 *
 * LLVM MC evaluates constant expressions, so negative literals are valid.
 * LXI_X_NEG(val) loads the 16-bit two's complement of val.
 * ========================================================================== */

#ifndef LXI_B
#define LXI_B(val)      "lxi b, " #val " \n\t"
#endif
#ifndef LXI_D
#define LXI_D(val)      "lxi d, " #val " \n\t"
#endif
#ifndef LXI_H_IMM
/* LXI_H_IMM avoids clashing with common uses of 'LXI_H' as a label. */
#define LXI_H_IMM(val)  "lxi h, " #val " \n\t"
#endif
#ifndef LXI_H_NEG
#define LXI_H_NEG(val)  "lxi h, (0 - " #val ") \n\t"
#endif
#ifndef LXI_D_NEG
#define LXI_D_NEG(val)  "lxi d, (0 - " #val ") \n\t"
#endif

/* ==========================================================================
 * Address-difference helpers
 *
 * MVI_A_TO_DIFF(from, to)  A  = (to - from) & 0xFF
 * LXI_B_TO_DIFF(from, to)  BC = to - from   (16-bit signed diff)
 * LXI_D_TO_DIFF(from, to)  DE = to - from
 * LXI_H_TO_DIFF(from, to)  HL = to - from
 *
 * Arguments must be C preprocessor integer constants that expand to
 * literals without the 'u' suffix (LLVM MC expression evaluation).
 * ========================================================================== */

#ifndef MVI_A_TO_DIFF
#define MVI_A_TO_DIFF(from, to) \
    "mvi a, ((" #to ") - (" #from ")) & 0xFF \n\t"
#endif
#ifndef LXI_B_TO_DIFF
#define LXI_B_TO_DIFF(from, to) \
    "lxi b, (" #to ") - (" #from ") \n\t"
#endif
#ifndef LXI_D_TO_DIFF
#define LXI_D_TO_DIFF(from, to) \
    "lxi d, (" #to ") - (" #from ") \n\t"
#endif
#ifndef LXI_H_TO_DIFF
#define LXI_H_TO_DIFF(from, to) \
    "lxi h, (" #to ") - (" #from ") \n\t"
#endif

/* ==========================================================================
 * HL / DE advancement helpers
 *
 * Use the INX/DCX variants for small diffs [1, 3]; use the BY_BC/DE
 * variants for larger diffs (saves cycles vs. many INX/DCX).
 *
 * HL_ADVANCE_INX(n)           INX H × n
 * HL_ADVANCE_DCX(n)           DCX H × n
 * HL_ADVANCE_BY_BC(from, to)  LXI B, diff; DAD B    (24 cc)
 * HL_ADVANCE_BY_DE(from, to)  LXI D, diff; DAD D    (24 cc)
 * HL_ADVANCE_BY_HL_BC(f,t)    LXI H, diff; DAD B    (24 cc)
 * HL_ADVANCE_BY_HL_DE(f,t)    LXI H, diff; DAD D    (24 cc)
 * HL_ADVANCE_BY_A(c)          Add signed 16-bit const c to HL via A  (40 cc)
 * DE_ADVANCE_INX(n)           INX D × n
 * DE_ADVANCE_DCX(n)           DCX D × n
 * ========================================================================== */

#ifndef HL_ADVANCE_INX
#define HL_ADVANCE_INX(n)               INX_H(n)
#endif
#ifndef HL_ADVANCE_DCX
#define HL_ADVANCE_DCX(n)               DCX_H(n)
#endif
#ifndef HL_ADVANCE_BY_BC
#define HL_ADVANCE_BY_BC(from, to)      LXI_B_TO_DIFF(from, to) "dad b \n\t"
#endif
#ifndef HL_ADVANCE_BY_DE
#define HL_ADVANCE_BY_DE(from, to)      LXI_D_TO_DIFF(from, to) "dad d \n\t"
#endif
#ifndef HL_ADVANCE_BY_HL_BC
#define HL_ADVANCE_BY_HL_BC(from, to)   LXI_H_TO_DIFF(from, to) "dad b \n\t"
#endif
#ifndef HL_ADVANCE_BY_HL_DE
#define HL_ADVANCE_BY_HL_DE(from, to)   LXI_H_TO_DIFF(from, to) "dad d \n\t"
#endif
#ifndef HL_ADVANCE_BY_A
/* Add a signed 16-bit constant c to HL using A as a scratch register (40 cc).
 * c must be a constant without the 'u' suffix. */
#define HL_ADVANCE_BY_A(c) \
    "mvi a, (" #c ") & 0xFF \n\t" \
    "add l \n\t" \
    "mov l, a \n\t" \
    "mvi a, ((" #c ") >> 8) & 0xFF \n\t" \
    "adc h \n\t" \
    "mov h, a \n\t"
#endif
#ifndef DE_ADVANCE_INX
#define DE_ADVANCE_INX(n)               INX_D(n)
#endif
#ifndef DE_ADVANCE_DCX
#define DE_ADVANCE_DCX(n)               DCX_D(n)
#endif

/* ==========================================================================
 * Register pair arithmetic
 * ========================================================================== */

/* BC += HL  (uses A; 40 cc) */
#ifndef BC_TO_BC_PLUS_HL
#define BC_TO_BC_PLUS_HL() \
    "mov a, c \n\t" \
    "add l \n\t" \
    "mov c, a \n\t" \
    "mov a, b \n\t" \
    "adc h \n\t" \
    "mov b, a \n\t"
#endif

/* BC += DE  (uses A; 40 cc) */
#ifndef BC_TO_BC_PLUS_DE
#define BC_TO_BC_PLUS_DE() \
    "mov a, c \n\t" \
    "add e \n\t" \
    "mov c, a \n\t" \
    "mov a, b \n\t" \
    "adc d \n\t" \
    "mov b, a \n\t"
#endif

/* ==========================================================================
 * HL / BC / DE  ←  A ± constant  (36–44 cc)
 *
 * Constants must be expressions without the 'u' suffix.
 * LLVM MC evaluates (c & 0xFF) and (c >> 8) at assembly time.
 * ========================================================================== */

/* HL = A + int16_const  (36 cc) */
#ifndef HL_TO_A_PLUS_INT16
#define HL_TO_A_PLUS_INT16(c) \
    asm ( \
        "adi <(" #c ")              \n" \
        "mov l, a                   \n" \
        "aci >(" #c ")             \n" \
        "sub l                      \n" \
        "mov h, a                   \n" \
    );
#endif

/* BC = A + int16_const  (36 cc) */
#ifndef BC_TO_A_PLUS_INT16
#define BC_TO_A_PLUS_INT16(c) \
    "adi (" #c ") & 0xFF \n\t" \
    "mov c, a \n\t" \
    "aci ((" #c ") >> 8) & 0xFF \n\t" \
    "sub c \n\t" \
    "mov b, a \n\t"
#endif

/* BC = A*2 + int16_const  (40 cc) */
#ifndef BC_TO_AX2_PLUS_INT16
#define BC_TO_AX2_PLUS_INT16(c) \
    "add a \n\t" \
    "adi (" #c ") & 0xFF \n\t" \
    "mov c, a \n\t" \
    "aci ((" #c ") >> 8) & 0xFF \n\t" \
    "sub c \n\t" \
    "mov b, a \n\t"
#endif

/* DE = A*2 + int16_const  (40 cc) */
#ifndef DE_TO_AX2_PLUS_INT16
#define DE_TO_AX2_PLUS_INT16(c) \
    "add a \n\t" \
    "adi (" #c ") & 0xFF \n\t" \
    "mov e, a \n\t" \
    "aci ((" #c ") >> 8) & 0xFF \n\t" \
    "sub e \n\t" \
    "mov d, a \n\t"
#endif

/* HL = A*2 + int16_const  (40 cc) */
#ifndef HL_TO_AX2_PLUS_INT16
#define HL_TO_AX2_PLUS_INT16(c) \
    "add a \n\t" \
    "adi (" #c ") & 0xFF \n\t" \
    "mov l, a \n\t" \
    "aci ((" #c ") >> 8) & 0xFF \n\t" \
    "sub l \n\t" \
    "mov h, a \n\t"
#endif

/* HL = A*4 + int16_const  (44 cc) */
#ifndef HL_TO_AX4_PLUS_INT16
#define HL_TO_AX4_PLUS_INT16(c) \
    ADD_A(2) \
    "adi (" #c ") & 0xFF \n\t" \
    "mov l, a \n\t" \
    "aci ((" #c ") >> 8) & 0xFF \n\t" \
    "sub l \n\t" \
    "mov h, a \n\t"
#endif

/* ==========================================================================
 * Flag and zero-test macros
 * ========================================================================== */

/* CPI_ZERO(int8_const) — test A for zero using ORA A.
 * Sets Z if A == 0; clears CY.  int8_const must equal 0.
 * (Matches v6_macros.asm: uses ORA A, not CPI 0.) */
#ifndef CPI_ZERO
#define CPI_ZERO(int8_const) "ora a \n\t"
#endif

/* A_TO_ZERO(int8_const) — set A = 0 using XRA A.
 * int8_const must equal 0 (e.g. RAM_DISK_OFF_CMD, PALETTE_UPD_REQ_NO). */
// V6C_INLINE
// void A_TO_ZERO(uint8_t _const, bool useXRA){
//     /* Compile-time assertion: int8_const must be 0. */
//     if (_const != 0) {
//         /* Force a compile-time error if _const is not zero. */
//         ((void)sizeof(char[(_const == 0) ? 1 : -1]));
//     }
//     if (useXRA) {
//         asm ("xra a \n");
//     } else {
//         asm ("mvi a, 0 \n");
//     }
// }
#ifndef A_TO_ZERO
#define A_TO_ZERO(int8_const, useXRA) \
    do { \
        /* Compile-time assertion: int8_const must be 0. */ \
        _Static_assert((int8_const) == 0, "A_TO_ZERO: int8_const must be 0"); \
        if (useXRA) { \
            asm ("XRA A         \n"); \
        } else { \
            asm ("MVI A, 0      \n"); \
        } \
    } while (0)
#endif

/* SET_CY(val) — set or clear the carry flag.
 * val must be the literal token 0 (clear) or 1 (set). */
#ifndef SET_CY
#define SET_CY(val)     SET_CY_##val
#define SET_CY_0        "ora a \n\t"    /* CY = 0 */
#define SET_CY_1        "stc \n\t"     /* CY = 1 */
#endif

/* ==========================================================================
 * RAM Disk macros
 *
 * Defaults use _V6C_RAM_DISK_PORT (0x11).
 *
 * For macros that save/restore ram_disk_mode the caller's TU must
 * declare:  extern uint8_t ram_disk_mode;
 *
 * Rule: the 'mode'/'cmd' argument must expand without 'u' suffix.
 * Use _V6C_RAM_DISK_* shadow constants defined above.
 * ========================================================================== */

/* RAM_DISK_ON(cmd) — load cmd, save to ram_disk_mode, enable. */
#ifndef RAM_DISK_ON
#define RAM_DISK_ON(cmd) \
    "mvi a, " _V6C_XSTR(cmd) " \n\t" \
    "sta ram_disk_mode \n\t" \
    "out " _V6C_RAM_DISK_PORT_S " \n\t"
#endif

/* RAM_DISK_ON_NO_RESTORE(cmd) — load cmd, enable; do NOT save mode. */
#ifndef RAM_DISK_ON_NO_RESTORE
#define RAM_DISK_ON_NO_RESTORE(cmd) \
    "mvi a, " _V6C_XSTR(cmd) " \n\t" \
    "out " _V6C_RAM_DISK_PORT_S " \n\t"
#endif

/* RAM_DISK_ON_BANK() — A holds bank cmd; save to ram_disk_mode and enable. */
#ifndef RAM_DISK_ON_BANK
#define RAM_DISK_ON_BANK() \
    "sta ram_disk_mode \n\t" \
    "out " _V6C_RAM_DISK_PORT_S " \n\t"
#endif

/* RAM_DISK_ON_BANK_NO_RESTORE() — A holds bank cmd; just send to port. */
#ifndef RAM_DISK_ON_BANK_NO_RESTORE
#define RAM_DISK_ON_BANK_NO_RESTORE() \
    "out " _V6C_RAM_DISK_PORT_S " \n\t"
#endif

/* RAM_DISK_OFF() — disable; save off-cmd to ram_disk_mode. */
#ifndef RAM_DISK_OFF
#define RAM_DISK_OFF() \
    "xra a \n\t" \
    "sta ram_disk_mode \n\t" \
    "out " _V6C_RAM_DISK_PORT_S " \n\t"
#endif

/* RAM_DISK_OFF_NO_RESTORE() — disable without saving mode. */
#ifndef RAM_DISK_OFF_NO_RESTORE
#define RAM_DISK_OFF_NO_RESTORE(useXRA, ram_disk_port) \
    A_TO_ZERO(RAM_DISK_OFF_CMD, useXRA); \
    asm ("OUT " _V6C_XSTR(ram_disk_port) " \n");
#endif


/* RAM_DISK_RESTORE() — reload mode from ram_disk_mode and re-enable.
 * Requires ram_disk_mode to be declared in the TU. */
#ifndef RAM_DISK_RESTORE
#define RAM_DISK_RESTORE(_ram_disk_port, _ram_disk_mode) \
    asm ( \
        "lda " _V6C_XSTR(_ram_disk_mode) "\n" \
        "out " _V6C_XSTR(_ram_disk_port) "    \n" \
    );
#endif

/* CALL_RAM_DISK_FUNC(func, cmd) — save mode, enable, call, disable. */
#ifndef CALL_RAM_DISK_FUNC
#define CALL_RAM_DISK_FUNC(func, cmd) \
    RAM_DISK_ON(cmd) \
    "call " #func " \n\t" \
    RAM_DISK_OFF()
#endif

/* CALL_RAM_DISK_FUNC_BANK(func) — A holds cmd; save mode, call, disable. */
#ifndef CALL_RAM_DISK_FUNC_BANK
#define CALL_RAM_DISK_FUNC_BANK(func) \
    RAM_DISK_ON_BANK() \
    "call " #func " \n\t" \
    RAM_DISK_OFF()
#endif

/* CALL_RAM_DISK_FUNC_NO_RESTORE(func, mode) — enable (no save), call,
 * disable (no save).  mode must expand without 'u' suffix. */
#ifndef CALL_RAM_DISK_FUNC_NO_RESTORE
#define CALL_RAM_DISK_FUNC_NO_RESTORE(func, mode) \
    RAM_DISK_ON_NO_RESTORE(mode) \
    "call " #func " \n\t" \
    RAM_DISK_OFF_NO_RESTORE()
#endif

/* ==========================================================================
 * Clamp / wrap macros
 *
 * Local labels use the %=-suffix to guarantee uniqueness per asm block.
 * The val_max argument is stringified directly; it must be a numeric
 * literal or a C preprocessor constant without the 'u' suffix.
 * ========================================================================== */

/* CLAMP_A(val_max) — if A > val_max, set A = val_max. */
#ifndef CLAMP_A
#define CLAMP_A(val_max) \
    "cpi (" #val_max ") + 1 \n\t" \
    "jc Lv6c_clamp_a%= \n\t" \
    "mvi a, " #val_max " \n\t" \
    "Lv6c_clamp_a%=: \n\t"
#endif

/* CLAMP_M(val_max) — if [HL] > val_max, set [HL] = val_max. */
#ifndef CLAMP_M
#define CLAMP_M(val_max) \
    "mov a, m \n\t" \
    "cpi (" #val_max ") + 1 \n\t" \
    "jc Lv6c_clamp_m%= \n\t" \
    "mvi m, " #val_max " \n\t" \
    "Lv6c_clamp_m%=: \n\t"
#endif

/* INR_CLAMP_M(val_max) — increment [HL] unless it already equals val_max.
 * cc: often 40, rarely 28. */
#ifndef INR_CLAMP_M
#define INR_CLAMP_M(val_max) \
    "mov a, m \n\t" \
    "cpi " #val_max " \n\t" \
    "jz Lv6c_inr_clamp%= \n\t" \
    "inr m \n\t" \
    "Lv6c_inr_clamp%=: \n\t"
#endif

/* INR_WRAP_M(val_max, no_wrap_label) — increment [HL]; if [HL] reaches
 * val_max reset it to 0 and fall through, otherwise jump to no_wrap_label.
 * no_wrap_label must be a bare label name (no quotes) already visible in
 * the enclosing asm block.
 * cc: often 48, rarely 40. */
#ifndef INR_WRAP_M
#define INR_WRAP_M(val_max, no_wrap_label) \
    "inr m \n\t" \
    "mvi a, " #val_max " \n\t" \
    "sub m \n\t" \
    "jnz " #no_wrap_label " \n\t" \
    "mov m, a \n\t"
#endif

/* ==========================================================================
 * Jump-table helpers
 * ========================================================================== */

/* JMP_4(dst) — 4-byte-aligned JMP (JMP + NOP pad). */
#ifndef JMP_4
#define JMP_4(dst)  "jmp " #dst " \n\t" "nop \n\t"
#endif

/* RET_4() — 4-byte-aligned RET (RET + 3 NOPs). */
#ifndef RET_4
#define RET_4()     "ret \n\t" NOP_(3)
#endif

/* ==========================================================================
 * Game update counter
 *
 * CHECK_GAME_UPDATE_COUNTER(game_updates_req, ints_per_update)
 *   Throttles the game loop.  Returns (via RM) if no full update
 *   interval has elapsed.  Decrements [HL] by ints_per_update.
 *
 *   game_updates_req — label/address of the pending-updates byte
 *                      (incremented by the interruption routine).
 *   ints_per_update  — literal integer 1–8 (number of ticks per update).
 *
 * Note: ints_per_update = 2 → 25 Hz update loop at 50 Hz interrupt rate.
 * ========================================================================== */
#ifndef CHECK_GAME_UPDATE_COUNTER
#define CHECK_GAME_UPDATE_COUNTER(game_updates_req, ints_per_update) \
    "lxi h, " #game_updates_req " \n\t" \
    "mov a, m \n\t" \
    "ora a \n\t" \
    "rm \n\t" \
    DCR_M(ints_per_update)
#endif

/* ==========================================================================
 * Debug / profiling macros
 *
 * Define SHOW_CPU_HIGHLOAD_ON_BORDER before including to enable.
 * When disabled, both macros expand to nothing.
 * ========================================================================== */
#ifdef SHOW_CPU_HIGHLOAD_ON_BORDER
#  ifndef DEBUG_BORDER_LINE
#  define DEBUG_BORDER_LINE(border_color_idx) \
    "mvi a, " _V6C_XSTR(_V6C_PORT0_OUT_OUT) " \n\t" \
    "out 0 \n\t" \
    "mvi a, " #border_color_idx " \n\t" \
    "out 2 \n\t" \
    "lda scr_offset_y \n\t" \
    "out 3 \n\t"
#  endif
#  ifndef DEBUG_HLT
#  define DEBUG_HLT()  "hlt \n\t"
#  endif
#else
#  ifndef DEBUG_BORDER_LINE
#  define DEBUG_BORDER_LINE(border_color_idx)  /* disabled */
#  endif
#  ifndef DEBUG_HLT
#  define DEBUG_HLT()                          /* disabled */
#  endif
#endif /* SHOW_CPU_HIGHLOAD_ON_BORDER */

#endif /* __V6C_V6C_MACROS_H */
