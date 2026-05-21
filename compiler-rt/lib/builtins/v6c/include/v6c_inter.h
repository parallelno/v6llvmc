/*===---- v6c_inter.h - V6C target-specific interrupt handling utilities ----===
 *
 * Interrupt and hardware setup.
 *
 *===------------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_INTER_H
#define __V6C_V6C_INTER_H

#ifndef __V6C__
#error "<v6c_inter.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include <v6c_rt_macros.h>
#include "v6c_consts.h"

/*
 * Minimal interrupt handler for when interrupts are enabled but no specific
 * handling is needed.
 */
V6C_INLINE
void v6c_set_empty_interrupt() {
    __asm__ volatile (
        "MVI A, %[ei] \n\t"
        "STA 0x38     \n\t"
        "MVI A, %[ret] \n\t"
        "STA 0x39      \n\t"
        :
        :  [ei] "i"(OPCODE_EI), [ret] "i"(OPCODE_RET)
        : "A"
    );
}


/*
 * Palette initialization routine.
 * IN: palette_end - pointer to a last byte of a 16-color palette in memory.
*/

V6C_NOINLINE
void v6c_set_palette(uint8_t* palette_end)
{
    register uint16_t pal_reg asm("HL") = (uint16_t)palette_end;

    __asm__ volatile (
            "hlt             \n"
            "mvi a, %[port]  \n"
            "out 0           \n"
            "mvi b, %[len]   \n"
         "1: mov a, b        \n"
			"out 2           \n"
			"mov a, m        \n"
			"out 0x0C        \n"
			"push psw        \n"
			"pop psw         \n"
			"push psw        \n"
			"pop psw         \n"
			"dcx h           \n"
			"dcr b           \n"
			"out 0x0C        \n"
			"jp	1b           \n"
            : /* no outputs */
            : "r"(pal_reg), [port] "i"(PORT0_OUT_OUT), [len] "i"(PALETTE_LEN-1)
            : "A", "B", "FLAGS"
    );
}

#endif /* __V6C_V6C_INTER_H */
