/*===---- v6c_inter.h - V6C target-specific interrupt handling utilities ----===
 *
 * Thin inline wrappers around the __builtin_v6c_* family. These map
 * directly onto i8080 instructions (IN, OUT, DI, EI, HLT, NOP) and are
 * always inlined; including this header has zero call overhead.
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
void set_empty_int() {
    __asm__ volatile (
        "mvi a, %[ret] \n\t"
        "sta 0x38      \n\t"
        :
        : [ret] "i"(OPCODE_RET)
    );
}


/*
 * Example palette initialization routine. The caller provides a pointer to a
 * 16-color palette in memory, and this function writes it out to the hardware
 * palette registers over PORT0.
 *
 * This is a `noinline` function to keep the body out of the caller's IR and
 * to ensure that the register constraints in the inline asm are respected even
 * under heavy register pressure in the caller. The body is pure inline asm with
 * no extended-asm operands, so all data flow in/out and clobbers are managed
 * by the caller's register-asm bindings plus the `noinline` attribute that
 * prevents reordering.
 *
 * Contract:
 *   IN:    HL = pointer to 16-color palette data (16 bytes)
 *   OUT:   none
 *   CLOBBERS: A, B, FLAGS
*/

V6C_NOINLINE
void palette_init(uint8_t* palette)
{
    register uint16_t pal_reg asm("HL") = (uint16_t)palette;

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
            : "r"(pal_reg), [port] "i"(PORT0_OUT_OUT), [len] "i"(PALETTE_LEN)
            : "A", "B", "FLAGS"
    );
    return;
}

#endif /* __V6C_V6C_INTER_H */
