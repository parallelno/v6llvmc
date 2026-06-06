/*===---- v6c_interrupt.h - V6C i8080 interrupt handler ---------------===*
 *
 * Interrupt support that allows safe stack manipulation in the main
 * program without disabling interrupts (DI/EI).
 *
 * Overview
 * --------
 * When the main program executes a `POP RP` to read from a stack-based
 * buffer, an interrupt may occur. The CPU then performs `PUSH PC`,
 * overwriting the two bytes currently pointed to by SP and corrupting
 * the buffer.
 *
 * This handler restores the corrupted register pair using BC.
 *
 * Requirements for correct operation
 * ---------------------------------
 * The main program must:
 *   1. Use only `POP B` to read stack-based data.
 *   2. Prepend two dummy bytes (0x00, 0x00) before the actual data so
 *      that a `PUSH PC` cannot overwrite meaningful content before the
 *      handler restores it.
 *
 * Public symbols
 * --------------
 *   interruption           — ISR entry point; mapped to INT_ADDR (0x38)
 *   ints_per_sec_counter   — countdown byte (from INTS_PER_SEC)
 *   game_draw_counter      — alias to frame counter (incremented per second)
 *   palette_update_request — flag byte; write non-zero to request update
 *
 *===------------------------------------------------------------------===*/

#ifndef __V6C_V6C_INTERRUPT_H
#define __V6C_V6C_INTERRUPT_H

#ifndef __V6C__
#error "<v6c_interrupt.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"
#include "v6c_consts.h"

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

#undef V6C_RT
#endif /* __V6C_V6C_INTERRUPT_H */
