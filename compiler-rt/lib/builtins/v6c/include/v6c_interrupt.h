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

#ifndef __V6C_V6C_INTERRUPT_H
#define __V6C_V6C_INTERRUPT_H

#ifndef __V6C__
#error "<v6c_interrupt.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"
#include "v6c_asm_macros.h"
#include "v6c_consts.h"
#include "v6c_display.h"
#include "v6c_controls.h"

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
        : [int_addr] "i"(INT_ADDR), "r" (_handler), [op_call] "i"(OPCODE_JMP)
        /* clobbers */
        : "A", "HL"
    );
}


V6C_NOINLINE
/*
 * interruption subroutine.
 *
 * Invoked by the hardware at INT_ADDR (0x38) via JMP.
 * Minimal handler for when interrupts are enabled but no specific handling is
 * needed. Mostly useful for tests to set a color palette.
 */
void v6c_empty_interrupt_handler() {
    v6c_ei();
    return;
}


V6C_NOINLINE
void v6c_set_empty_interrupt_handler() {
    v6c_set_interrupt_handler(v6c_empty_interrupt_handler);
}


/* Counter reset every second. Helps to count the game updates per second. */
static uint8_t ints_per_sec_counter = 0;

/* ram_disk_mode: persists the active RAM Disk bank command so
 * RAM_DISK_RESTORE() (from v6c_macros.h) can re-enable it on exit. */
uint8_t ram_disk_mode = 0;

// extern void controls_check(void);
// extern uint8_t border_color_idx;
// extern uint8_t scr_offset_y;
// extern uint8_t game_updates_required;

/* ------------------------------------------------------------------
 * interruption subroutine.
 *
 * Invoked by the hardware at INT_ADDR (0x38) via JMP.
 * Manages its own stack, supports fast data reading via stack in the main
 * program when interrupts are enabled.
 *
 * Why do we need this complexity?
 * When the main program is doing "POP BC" operation for fast data read/copy,
 * and an interruption happens, then i8080 performs "push PC" corrupting the
 * data where SP register was pointing to. This subroutine restores the corrupted
 * data.
 *
 * Requirements:
 * BC - the only register pair to read data from the stack in the main program.
 * Each data block read by stack has to have two extra bytes 0,0 stored in front
 * of the actual data to not let the "push PC" corrupts the data before BC pair
 * gets it.
 *
 * It assumes:
 * - [SP]   = return address (low byte)
 * - [SP+1] = return address (high byte)
 * - BC contains the data to be restored back to SP address.
 * How this solves the problem:
 * 1. It swaps the return address with the HL pair in the stack.
 * 2. Saves the return address from HL to the self-modifying JMP instruction.
 * 3. Gets the original HL from the stack and store it to the self-modifying LXI
 * instruction.
 * 4. Store PSW via Push PSW; POP H; SHLD direct to the reserved stack space for
 * PSW in the interruption stack.
 * 5. Gets SP via DAD SP and stores it to the self-modifying LXI instruction.
 * 6. Restores the two bytes corrupted by "push PC" via PUSH B.
 * 7. Switches to the dedicated interruption stack.
 * 8. Routine main logic.
 * 9. On exit, restores registers, PSW, and SP, re-enables interrupts, then JMPs
 * to the saved return address.
 * ------------------------------------------------------------------ */
V6C_INLINE
void v6c_interrupt_handler(void) {
    __asm__ volatile (

        // Save the interrupt return address (hardware-pushed PC) into
        // the self-modifying JMP immediate at .L_INT_RETURN+1.
        "XTHL                                   \n"   // HL = ret addr, [SP] = old HL
        "SHLD .L_INT_RETURN + 1                 \n"
        "POP  H                                 \n"   // HL = old HL
        "SHLD .L_INT_RESTORE_HL + 1             \n"

        // Save PSW to the bottom of the interrupt stack so PUSH PSW
        // later (via DAD; SHLD;) lands in the right slot.
        "PUSH PSW                               \n"
        "POP  H                                 \n"   // HL = PSW (A:flags)
        "SHLD %[stack_int_addr_m2]              \n"

        // Save current SP so it can be restored on exit.
        "LXI  H, 0                              \n"
        "DAD  SP                                \n"   // HL = SP
        "SHLD .L_INT_RESTORE_SP + 1             \n"

        // Restore two bytes possibly corrupted by the interrupt's `PUSH PC`.
        // The main program protects its stack-read data with two leading zero
        // bytes so this `PUSH B` lands in the padding.
        "PUSH B                                 \n"
        : /* no outputs */
          /* input constraints */
        : [stack_int_addr_m2] "i"(STACK_INTERRUPTION_ADDR - 2)
        /* no clobbers */
        :
    );
        // Switch to the dedicated interrupt stack.
        RAM_DISK_OFF_NO_RESTORE(true, RAM_DISK_PORT)

    __asm__ volatile (
        "LXI  SP, %[stack_int_addr_m2]          \n"
        "PUSH B                                 \n"
        "PUSH D                                 \n"
        : /* no outputs */
          /* input constraints */
        : [stack_int_addr_m2] "i"(STACK_INTERRUPTION_ADDR - 2)
        /* no clobbers */
        :
    );
        // ================================================================
        // Interruption main logic
        // ================================================================
        controls_check();

    __asm__ volatile (
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

        // ================================================================
        // Exit sequence
        // ================================================================
        "POP  D                                 \n"
        "POP  B                                 \n"
        "POP  PSW                               \n"
        "MOV  L, A                              \n" // stash A before RAM_DISK_RESTORE clobbers it
        : /* no outputs */
          /* input constraints */
        : [stack_int_addr_m2] "i"(STACK_INTERRUPTION_ADDR - 2)
        /* no clobbers */
        :
    );
        RAM_DISK_RESTORE(RAM_DISK_PORT, ram_disk_mode);

    __asm__ volatile (
        "MOV  A, L                              \n"   /* restore A                    */

        ".L_INT_RESTORE_HL:                       \n"
        "LXI  H, 0                              \n"   /* immediate patched at runtime  */
        ".L_INT_RESTORE_SP:                       \n"
        "LXI  SP, 0                             \n"   /* immediate patched at runtime  */
        "EI                                     \n"
        ".L_INT_RETURN:                          \n"
        "JMP  0                                 \n"   /* immediate patched at runtime  */
    );
}

#undef V6C_RT
#endif /* __V6C_V6C_INTERRUPT_H */
