/*===---- v6c_interruption.h - V6C i8080 interruption handler ------------===
 *
 * The interruption sub which supports stack manipulations in the main
 * program without DI/EI.
 *
 * Problem solved
 * --------------
 * If the main program is executing a "POP RP" to read data from a
 * stack-addressed buffer and an interrupt fires, the CPU does PUSH PC,
 * corrupting the two bytes SP was pointing at.  The handler below
 * restores the corrupted pair using BC.  For this to work the main
 * program must:
 *   1. Use only POP B when reading stack-addressed data.
 *   2. Store two extra 0,0 bytes before the actual data so PUSH PC
 *      cannot corrupt real content before BC can restore it.
 *
 * Public symbols emitted
 * ----------------------
 *   interruption          — ISR entry point; wire to INT_ADDR (0x38).
 *   ints_per_sec_counter  — mutable byte: counts down from INTS_PER_SEC.
 *   game_draw_counter     — alias for the frame-count self-modifying byte
 *                           (incremented every second by the FPS logic).
 *   palette_update_request — alias for the palette-update flag byte
 *                           (write non-zero to request a palette flush).
 *
 * Macros used by this handler
 * ---------------------------
 * All macros below are provided by v6c_macros.h (included above).
 * Override individual macros before including this header if needed.
 *
 *   RAM_DISK_OFF_NO_RESTORE()   — XRA A; OUT 0x11
 *   RAM_DISK_ON_BANK_NO_RESTORE()— OUT 0x11  (A holds bank cmd)
 *   CALL_RAM_DISK_FUNC_NO_RESTORE(func, mode)
 *       Enable RAM Disk (no mode save), call func, disable.
 *       mode must expand WITHOUT 'u' suffix — use _V6C_RAM_DISK_*
 *       shadow constants from v6c_macros.h.  PERMANENT_SONG01_RAM_DISK_M
 *       must be defined by the project without 'u':
 *           #define PERMANENT_SONG01_RAM_DISK_M  0x10
 *   RAM_DISK_RESTORE()          — LDA ram_disk_mode; OUT 0x11
 *   CPI_ZERO(x)                 — ORA A  (Z set iff A == 0)
 *   A_TO_ZERO(x)                — XRA A
 *
 * Required external symbols (must be linked)
 * -------------------------------------------
 *   controls_check    — void(void)  process input
 *   set_palette_int   — void(void)  flush palette during interruption
 *                       (HL must point to palette+PALETTE_LEN-1 on entry)
 *   palette           — uint8_t[PALETTE_LEN]
 *   border_color_idx  — uint8_t
 *   scr_offset_y      — uint8_t
 *   game_updates_required — uint8_t counter incremented each frame
 *
 * Single-TU rule
 * --------------
 * This header emits global assembly symbols.  Include it from EXACTLY
 * ONE .c translation unit to avoid duplicate-symbol link errors.
 *
 * Linkage: V6C_RT (static naked noinline used v6c_rt_helper), same
 * strategy as v6c_arith.h.  --gc-sections prunes unused copies.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_INTERRUPTION_H
#define __V6C_V6C_INTERRUPTION_H

#ifndef __V6C__
#error "<v6c_interruption.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"
#include "v6c_consts.h"

/* ------------------------------------------------------------------
 * Project-specific asm-string macros.  Override before including.
 * ------------------------------------------------------------------ */

#ifndef RAM_DISK_OFF_NO_RESTORE
/* Load RAM_DISK_OFF_CMD (0) into A and send to RAM_DISK_PORT (0x11). */
#define RAM_DISK_OFF_NO_RESTORE() \
    "mvi a, 0 \n\t" \
    "out 0x11 \n\t"
#endif

#ifndef CALL_RAM_DISK_FUNC_NO_RESTORE
/* No default: enable RAM Disk, call func, disable.
 * Define as:
 *   #define CALL_RAM_DISK_FUNC_NO_RESTORE(func, mode) \
 *       "mvi a, <numeric_mode> \n\t"                  \
 *       "out 0x11 \n\t"                               \
 *       "call " #func " \n\t"                         \
 *       "mvi a, 0 \n\t"                               \
 *       "out 0x11 \n\t"
 */
#define CALL_RAM_DISK_FUNC_NO_RESTORE(func, mode)   /* skipped — define this macro */
#endif

#ifndef RAM_DISK_RESTORE
/* Default: leave RAM Disk disabled after the interruption returns.
 * Override if the main program requires a persistent RAM Disk mode. */
#define RAM_DISK_RESTORE() /* no-op */
#endif

#ifndef CPI_ZERO
/* Compare A against 0 (the value of PALETTE_UPD_REQ_NO). */
#define CPI_ZERO(const_name) "cpi 0 \n\t"
#endif

#ifndef A_TO_ZERO
/* Set A = 0 (the value of PALETTE_UPD_REQ_NO). */
#define A_TO_ZERO(const_name) "xra a \n\t"
#endif

/* ------------------------------------------------------------------
 * Forward declarations for external project symbols.
 * ------------------------------------------------------------------ */
/* ram_disk_mode: persists the active RAM Disk bank command so
 * RAM_DISK_RESTORE() (from v6c_macros.h) can re-enable it on exit. */
extern uint8_t ram_disk_mode;

/* ram_disk_mode: persists the active RAM Disk bank command so
 * RAM_DISK_RESTORE() can re-enable it on exit from the interruption. */
extern uint8_t ram_disk_mode;

extern void controls_check(void);
/* set_palette_int: called with HL = &palette[PALETTE_LEN-1] on entry. */
extern void set_palette_int(void);
extern uint8_t palette[];
extern uint8_t border_color_idx;
extern uint8_t scr_offset_y;
extern uint8_t game_updates_required;

/* ------------------------------------------------------------------
 * interruption — ISR entry point.
 *
 * Invoked by the hardware at INT_ADDR (0x38) via a JMP or RST 7.
 * Does NOT use the V6C C calling convention; manages its own stack.
 *
 * Stack layout on entry (i8080 auto-pushes PC on interrupt):
 *   [SP]   = return address (low byte)
 *   [SP+1] = return address (high byte)
 *
 * Exit: restores all registers, re-enables interrupts, then JMPs
 * to the saved return address (EI + JMP instead of RETI).
 *
 * Asm-constant derivations (all from v6c_consts.h):
 *   STACK_MAIN_PROGRAM_ADDR    = 0x8000 - 2            = 0x7FFE
 *   STACK_INTERRUPTION_ADDR    = 0x7FFE - 48           = 0x7FCE
 *   STACK_INTERRUPTION_ADDR-2  = 0x7FCE - 2            = 0x7FCC
 *   PORT0_OUT_OUT              = 0x88
 *   PALETTE_LEN - 1            = 15
 *   INTS_PER_SEC               = 50
 * ------------------------------------------------------------------ */
V6C_RT void interruption(void) {
    __asm__ volatile (

        /* ---- entry point ----------------------------------------- */
        "memusage_v6_interruption:              \n"
        "interruption:                          \n\t"

        /* Save the interrupt return address (hardware-pushed PC) into
         * the self-modifying JMP immediate at .Lint_return+1.         */
        "XTHL                                   \n\t"   /* HL = ret addr, [SP] = old HL */
        "SHLD .Lint_return + 1                  \n\t"
        "POP  H                                 \n\t"   /* HL = old HL                  */
        "SHLD .Lint_restoreHL + 1               \n\t"

        /* Save PSW to the bottom of the interrupt stack so PUSH PSW
         * later (via DAD / SHLD) lands in the right slot.             */
        "PUSH PSW                               \n\t"
        "POP  H                                 \n\t"   /* HL = PSW (A:flags)           */
        "SHLD 0x7FCC                            \n\t"   /* STACK_INTERRUPTION_ADDR - 2  */

        /* Save current SP so it can be restored on exit.             */
        "LXI  H, 0                              \n\t"
        "DAD  SP                                \n\t"   /* HL = SP                      */
        "SHLD .Lint_restoreSP + 1               \n\t"

        /* Restore two bytes corrupted by the interrupt's PUSH PC.
         * The main program protects its stack-read data with two
         * leading zero bytes so this PUSH B lands in the padding.    */
        "PUSH B                                 \n\t"

        /* Switch to the dedicated interrupt stack.                   */
        RAM_DISK_OFF_NO_RESTORE()
        "LXI  SP, 0x7FCC                        \n\t"   /* STACK_INTERRUPTION_ADDR - 2  */
        "PUSH B                                 \n\t"
        "PUSH D                                 \n\t"

        /* ================================================================
         * Interruption main logic
         * ================================================================ */
        "CALL controls_check                    \n\t"

        /* -- Palette update check ----------------------------------- */
        ".Lint_pal_upd_req_:                    \n\t"
        "MVI  A, 0                              \n\t"   /* PALETTE_UPD_REQ_NO = 0; self-modifying */
        CPI_ZERO(PALETTE_UPD_REQ_NO)
        "JZ   Lint_set_border_scroll%=          \n\t"
        /* Flush palette: HL must point to palette + PALETTE_LEN - 1. */
        "LXI  H, palette + 15                   \n\t"   /* palette + PALETTE_LEN - 1    */
        "CALL set_palette_int                   \n\t"
        /* Reset the palette-update flag (patches the MVI A immediate above). */
        A_TO_ZERO(PALETTE_UPD_REQ_NO)
        "STA  palette_update_request            \n\t"

        "Lint_set_border_scroll%=:              \n\t"
        /* -- Border colour + vertical scroll + frame sync ---------- */
        "MVI  A, 0x88                           \n\t"   /* PORT0_OUT_OUT                */
        "OUT  0                                 \n\t"
        "LDA  border_color_idx                  \n\t"
        "OUT  2                                 \n\t"
        "LDA  scr_offset_y                      \n\t"
        "OUT  3                                 \n\t"

        /* Signal the main loop that a new frame is ready.            */
        "LXI  H, game_updates_required          \n\t"
        "INR  M                                 \n\t"

        /* -- FPS counter ------------------------------------------- */
        "LXI  H, ints_per_sec_counter           \n\t"
        "DCR  M                                 \n\t"
        "JNZ  Lint_no_fps_update%=              \n\t"

        /* One second elapsed: latch the frame count and reset.       */
        ".Lint_fps:                             \n\t"
        "LXI  H, 0                              \n\t"   /* TEMP_WORD; patched at runtime */
        /*
         * (FPS display omitted — handled by the Devector emulator script.)
         * Original site:
         *   MOV A, L
         *   draw_fps()
         */
        "LXI  H, 0                              \n\t"   /* reset fps accumulator        */
        "SHLD .Lint_fps + 1                     \n\t"
        "LXI  H, ints_per_sec_counter           \n\t"
        "MVI  M, 50                             \n\t"   /* INTS_PER_SEC                 */
        "Lint_no_fps_update%=:                  \n\t"

        /* ================================================================
         * Music update (RAM Disk function call)
         * ================================================================ */
        /* mode: PERMANENT_SONG01_RAM_DISK_M must be defined without 'u' suffix.
         * Example: #define PERMANENT_SONG01_RAM_DISK_M  0x10              */
        /* PERMANENT_SONG01_RAM_DISK_M must be defined without 'u' suffix
         * (e.g. #define PERMANENT_SONG01_RAM_DISK_M 0x10) for asm use.   */
        CALL_RAM_DISK_FUNC_NO_RESTORE(v6_sound_update, PERMANENT_SONG01_RAM_DISK_M | _V6C_RAM_DISK_M_8F)

        /* -- Restore registers and return -------------------------- */
        "POP  D                                 \n\t"
        "POP  B                                 \n\t"
        "POP  PSW                               \n\t"
        "MOV  L, A                              \n\t"   /* stash A before RAM_DISK_RESTORE clobbers it */
        RAM_DISK_RESTORE()
        "MOV  A, L                              \n\t"   /* restore A                    */

        ".Lint_restoreHL:                       \n\t"
        "LXI  H, 0                              \n\t"   /* immediate patched at runtime  */
        ".Lint_restoreSP:                       \n\t"
        "LXI  SP, 0                             \n\t"   /* immediate patched at runtime  */
        "EI                                     \n\t"
        ".Lint_return:                          \n\t"
        "JMP  0                                 \n\t"   /* immediate patched at runtime  */

        /* ---- Data: interrupt tick counter (one byte in code space) */
        "ints_per_sec_counter:                  \n\t"
        ".byte 50                               \n\t"   /* INTS_PER_SEC                 */

        /* ---- Assembler equates for self-modifying code targets ---- */
        /* game_draw_counter  — points to the frame-count LXI H immediate
         *                      (updated every second by the FPS block).  */
        "game_draw_counter    = .Lint_fps + 1   \n\t"
        /* palette_update_request — points to the MVI A immediate in the
         *                          palette-update-request self-mod site.  */
        "palette_update_request = .Lint_pal_upd_req_ + 1 \n\t"
    );
}

#undef V6C_RT
#endif /* __V6C_V6C_INTERRUPTION_H */
