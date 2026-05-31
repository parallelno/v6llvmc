/*===---- v6c_text_ex_consts.h - V6C extended text special character codes ===
 *
 * Special byte codes used within extended text string data.
 * Translated from v6_text_ex_consts.asm.
 *
 * These values appear inline inside text data sequences passed to the
 * extended text renderer (see v6c_text_ex_draw.h).
 *
 *===----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_TEXT_EX_CONSTS_H
#define __V6C_V6C_TEXT_EX_CONSTS_H

#ifndef __V6C__
#error "<v6c_text_ex_consts.h> is only valid for the V6C target"
#endif

#include <stdint.h>

/* =======================================================
 * In-band text-data control codes
 * ======================================================= */

/** Start a new line within the same paragraph. */
#define _LINE_BREAK_    ((uint8_t)0x6Au)

/** Start a new paragraph (implies larger vertical gap than a line break). */
#define _PARAG_BREAK_   ((uint8_t)0xFFu)

/** End-of-data sentinel: terminates the text data stream. */
#define _EOD_           ((uint8_t)0x00u)

#endif /* __V6C_V6C_TEXT_EX_CONSTS_H */
