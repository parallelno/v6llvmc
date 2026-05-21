/*===---- v6c.h - V6C target-specific hardware instruction wrappers -------===
 *
 * Inline asm wrappers for i8080 instructions (IN, OUT, DI, EI, HLT, NOP,
 * LXI SP).  Always inlined; including this header has zero call overhead.
 *
 *===-----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_H
#define __V6C_V6C_H

#ifndef __V6C__
#error "<v6c.h> is only valid for the V6C target"
#endif

#include <stdint.h>
#include "v6c_rt_macros.h"

V6C_INLINE
uint8_t v6c_in(uint8_t port) {
    register uint8_t in_val asm("A");
    asm(
        "in %[_port]            \n\t"
        : "=r"(in_val)
        : [_port] "i"(port) /* input constraint: immediate value */
        : "FLAGS" /* clobbers */
    );
    return in_val;
}

V6C_INLINE
void v6c_out(uint8_t port, uint8_t val) {

    asm(
        "mov a, %[_val]         \n\t"
        "out %[_port]           \n\t"
        :
        : [_val] "r"(val), [_port] "i"(port) /* input constraints */
        : "A", "FLAGS" /* clobbers */
    );
}

V6C_INLINE
void v6c_di(void)  { asm ("di"); }

V6C_INLINE
void v6c_ei(void)  { asm ("ei"); }

V6C_INLINE
void v6c_hlt(void) { asm("hlt"); }

V6C_INLINE
void v6c_nop(void) { asm("nop"); }

V6C_INLINE
void v6c_set_sp(uint16_t sp) {
    asm(
        "lxi sp, %0"
        :/* no output */
        : "i"(sp) /* input constraint: immediate value */
        : "SP" /* clobbers stack pointer */
    );
}

#endif /* __V6C_V6C_H */
