/*===---- v6c_os_macros.h - V6C OS system-call inline-asm macros ----------===
 *
 * Inline-asm macros for issuing RDS/CP/M BDOS system calls.
 * Translated from v6_os_macros.asm.
 *
 * Macro summary
 * -------------
 * SYS_CALL(func_id)
 *     Invoke BDOS with C = func_id.  Used when no DE argument is needed.
 *     Clobbers: A, BC, DE, HL, FLAGS.
 *
 * SYS_CALL_D(func_id, d_addr)
 *     Invoke BDOS with C = func_id, DE = d_addr.
 *     d_addr must be a constant label or integer — it is stringified and
 *     placed directly into the asm string.
 *     Clobbers: A, BC, DE, HL, FLAGS.
 *
 * Both macros bracket the CALL with DI/DI to prevent the interrupt
 * routine from corrupting BDOS state.  The DI after the call ensures
 * interrupts are re-disabled for the surrounding game code.
 *
 * 'u'-suffix rule: func_id and d_addr must expand without the 'u'
 * suffix (use plain integer literals or _V6C_* shadow constants).
 *
 *===----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_OS_MACROS_H
#define __V6C_V6C_OS_MACROS_H

#ifndef __V6C__
#error "<v6c_os_macros.h> is only valid for the V6C target"
#endif

#include "v6c_os_consts.h"
#include "v6c_macros.h"     /* _V6C_XSTR, _V6C_STR */

/* Internal stringify helpers (may already be defined by v6c_macros.h) */
#ifndef _V6C_STR
#  define _V6C_STR(x)  #x
#endif
#ifndef _V6C_XSTR
#  define _V6C_XSTR(x) _V6C_STR(x)
#endif

/* Asm-safe CPM_BDOS address (no 'u' suffix) */
#define _V6C_CPM_BDOS   0x0005

/* ------------------------------------------------------------------
 * SYS_CALL(func_id)
 *   C = func_id
 *   call CPM_BDOS
 * ------------------------------------------------------------------ */
#ifndef SYS_CALL
#define SYS_CALL(func_id) \
    __asm__ volatile( \
        "mvi c, " _V6C_XSTR(func_id) " \n\t" \
        "di \n\t" \
        "call " _V6C_XSTR(_V6C_CPM_BDOS) " \n\t" \
        "di \n\t" \
        ::: "A", "BC", "DE", "HL", "FLAGS" \
    )
#endif

/* ------------------------------------------------------------------
 * SYS_CALL_D(func_id, d_addr)
 *   C = func_id,  DE = d_addr (constant label or integer)
 *   call CPM_BDOS
 * ------------------------------------------------------------------ */
#ifndef SYS_CALL_D
#define SYS_CALL_D(func_id, d_addr) \
    __asm__ volatile( \
        "mvi c, " _V6C_XSTR(func_id) " \n\t" \
        "lxi d, " #d_addr " \n\t" \
        "di \n\t" \
        "call " _V6C_XSTR(_V6C_CPM_BDOS) " \n\t" \
        "di \n\t" \
        ::: "A", "BC", "DE", "HL", "FLAGS" \
    )
#endif

#endif /* __V6C_V6C_OS_MACROS_H */
