/*===---- v6c_interrupt.h - V6C i8080 interruption handler ------------===
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
 *   v6c_set_palette   — void(void)  flush palette during interruption
 *                       (HL must point to __palette+PALETTE_LEN-1 on entry)
 *   __palette         — uint8_t[PALETTE_LEN]
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
#include "v6c_display.h"


V6C_INLINE
void v6c_set_interrupt_handler(void* handler) {
    // `handler` must be in HL according the calling convention.
    register void* _handler asm("HL") = handler;
    __asm__ volatile (
        "MVI A, %[op_call]          \n"
        "STA %[int_addr]            \n"
        "SHLD %[int_addr] + 1       \n"
        : /* no outputs */
          /* input constraints */
        : [int_addr] "i"(INT_ADDR), "r" (_handler), [op_call] "i"(OPCODE_CALL)
        /* clobbers */
        : "A", "HL"
    );
}


V6C_NOINLINE
/*
 * Minimal interrupt handler for when interrupts are enabled but no specific
 * handling is needed. Mostly useful for tests to set a color palette.
 */
void v6c_empty_interrupt_handler() {
    v6c_ei();
    return;
}


V6C_NOINLINE
void v6c_set_empty_interrupt_handler() {
    v6c_set_interrupt_handler(v6c_empty_interrupt_handler);
}


/*
 * Counter reset every second. Helps to count the game updates per second.
 */
static uint8_t ints_per_sec_counter = 0;

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
V6C_RT void v6c_interrupt(void) {
    __asm__ volatile (

        /* Save the interrupt return address (hardware-pushed PC) into
         * the self-modifying JMP immediate at .Lint_return+1.         */
        "XTHL                                   \n"   /* HL = ret addr, [SP] = old HL */
        // "SHLD .Lint_return + 1                  \n"
        // "POP  H                                 \n"   /* HL = old HL                  */
        // "SHLD .Lint_restoreHL + 1               \n"

        // /* Save PSW to the bottom of the interrupt stack so PUSH PSW
        //  * later (via DAD / SHLD) lands in the right slot.             */
        // "PUSH PSW                               \n"
        // "POP  H                                 \n"   /* HL = PSW (A:flags)           */
        // "SHLD 0x7FCC                            \n"   /* STACK_INTERRUPTION_ADDR - 2  */

        // /* Save current SP so it can be restored on exit.             */
        // "LXI  H, 0                              \n"
        // "DAD  SP                                \n"   /* HL = SP                      */
        // "SHLD .Lint_restoreSP + 1               \n"

        // /* Restore two bytes corrupted by the interrupt's PUSH PC.
        //  * The main program protects its stack-read data with two
        //  * leading zero bytes so this PUSH B lands in the padding.    */
        // "PUSH B                                 \n"

        // /* Switch to the dedicated interrupt stack.                   */
        // //RAM_DISK_OFF_NO_RESTORE()
        // "LXI  SP, 0x7FCC                        \n"   /* STACK_INTERRUPTION_ADDR - 2  */
        // "PUSH B                                 \n"
        // "PUSH D                                 \n"

        // /* ================================================================
        //  * Interruption main logic
        //  * ================================================================ */
        // "CALL controls_check                    \n"

        // /* -- Palette update check ----------------------------------- */
        // ".Lint_pal_upd_req_:                    \n"
        // "MVI  A, 0                              \n"   /* PALETTE_UPD_REQ_NO = 0; self-modifying */
        // //CPI_ZERO(PALETTE_UPD_REQ_NO)
        // "JZ   Lint_set_border_scroll%=          \n"
        // /* Flush palette: HL must point to palette + PALETTE_LEN - 1. */
        // "LXI  H, %[palette_end]               \n"   /* palette + PALETTE_LEN - 1    */
        // "XRA A                                  \n"   /* set wait_for_vsync=false for the CALL below   */
        // "CALL %[v6c_set_palette]                 \n"
        // /* Reset the palette-update flag (patches the MVI A immediate above). */
        // //A_TO_ZERO(PALETTE_UPD_REQ_NO)
        // "STA  .Lint_pal_upd_req_ + 1            \n"

        // "Lint_set_border_scroll%=:              \n"
        // /* -- Border colour + vertical scroll + frame sync ---------- */
        // "MVI  A, 0x88                           \n"   /* PORT0_OUT_OUT                */
        // "OUT  0                                 \n"
        // "LDA  %[border_color_idx]                  \n"
        // "OUT  2                                 \n"
        // "LDA  %[scr_offset_y]                      \n"
        // "OUT  3                                 \n"

        // /* Signal the main loop that a new frame is ready.            */
        // "LXI  H, %[game_updates_required]          \n"
        // "INR  M                                 \n"

        // /* -- FPS counter ------------------------------------------- */
        // "LXI  H, &ints_per_sec_counter           \n"
        // "DCR  M                                 \n"
        // "JNZ  Lint_no_fps_update%=              \n"

        // /* One second elapsed: latch the frame count and reset.       */
        // ".Lint_fps:                             \n"
        // "LXI  H, 0                              \n"   /* TEMP_WORD; patched at runtime */
        // /*
        //  * (FPS display omitted — handled by the Devector emulator script.)
        //  * Original site:
        //  *   MOV A, L
        //  *   draw_fps()
        //  */
        // "LXI  H, 0                              \n"   /* reset fps accumulator        */
        // "SHLD .Lint_fps + 1                     \n"
        // "LXI  H, &ints_per_sec_counter           \n"
        // "MVI  M, 50                             \n"   /* INTS_PER_SEC                 */
        // "Lint_no_fps_update%=:                  \n"

        // /* ================================================================
        //  * Music update (RAM Disk function call)
        //  * ================================================================ */
        // /* mode: PERMANENT_SONG01_RAM_DISK_M must be defined without 'u' suffix.
        //  * Example: #define PERMANENT_SONG01_RAM_DISK_M  0x10              */
        // /* PERMANENT_SONG01_RAM_DISK_M must be defined without 'u' suffix
        //  * (e.g. #define PERMANENT_SONG01_RAM_DISK_M 0x10) for asm use.   */
        // //CALL_RAM_DISK_FUNC_NO_RESTORE(v6_sound_update, PERMANENT_SONG01_RAM_DISK_M | _V6C_RAM_DISK_M_8F)

        // /* -- Restore registers and return -------------------------- */
        // "POP  D                                 \n"
        // "POP  B                                 \n"
        // "POP  PSW                               \n"
        // "MOV  L, A                              \n"   /* stash A before RAM_DISK_RESTORE clobbers it */
        // //RAM_DISK_RESTORE()
        // "MOV  A, L                              \n"   /* restore A                    */

        // ".Lint_restoreHL:                       \n"
        // "LXI  H, 0                              \n"   /* immediate patched at runtime  */
        // ".Lint_restoreSP:                       \n"
        // "LXI  SP, 0                             \n"   /* immediate patched at runtime  */
        // "EI                                     \n"
        // ".Lint_return:                          \n"
        // "JMP  0                                 \n"   /* immediate patched at runtime  */

        // /* ---- Assembler equates for self-modifying code targets ---- */
        // /* game_draw_counter  — points to the frame-count LXI H immediate
        //  *                      (updated every second by the FPS block).  */
        // "game_draw_counter    = .Lint_fps + 1   \n"
        /* palette_update_request — points to the MVI A immediate in the
         *                          palette-update-request self-mod site.  */
//        "palette_update_request = .Lint_pal_upd_req_ + 1 \n"
        : /* no outputs */
          /* input constraints */
        :
        // [controls_check] "i"(controls_check),
        //   [palette_end] "i"(__palette + PALETTE_LEN - 1),
        //   [v6c_set_palette] "i"(v6c_set_palette),
        //   [border_color_idx] "i"(border_color_idx),
        //   [scr_offset_y] "i"(scr_offset_y),
        //   [game_updates_required] "i"(game_updates_required)
    );
}

#undef V6C_RT
#endif /* __V6C_V6C_INTERRUPTION_H */
