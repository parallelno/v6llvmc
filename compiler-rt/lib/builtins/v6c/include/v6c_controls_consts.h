/*===---- v6c_controls_consts.h - V6C keyboard and joystick constants -----===
 *
 * Key codes, joystick codes, and control action codes for the V6C / Vector-06c
 * input system.  Translated from v6_controls_consts.asm.
 *
 * Key encoding matrix:
 *
 *              columns
 *     |  7    6    5    4    3    2    1    0
 * ----+------------------------------------------
 *   7 | SPC   ^    ]    \    [    Z    Y    X
 *   6 |  W    V    U    T    S    R    Q    P
 * r 5 |  O    N    M    L    K    J    I    H
 * o 4 |  G    F    E    D    C    B    A    @
 * w 3 |  /    .    =    ,    ;    :    9    8
 * s 2 |  7    6    5    4    3    2    1    0
 *   1 | F5   F4   F3   F2   F1  AR2  STR  LDA   (LDA = left diagonal arrow)
 *   0 | DN   RT   UP  LFT  ZAB  VK   PS   TAB
 *
 * Usage:
 *   mvi a, KEY_CODE_ROW_0  ; select row
 *   out 3                  ; latch row
 *   in  2                  ; read columns (0 = pressed)
 *
 * Control code format:
 *   Bits: FIRE1 FIRE2 KEY_SPACE RETURN DOWN UP LEFT RIGHT
 *   Bit = 1 means the action is active (pressed).
 *
 *===----------------------------------------------------------------------===
 */

#ifndef __V6C_V6C_CONTROLS_CONSTS_H
#define __V6C_V6C_CONTROLS_CONSTS_H

#ifndef __V6C__
#error "<v6c_controls_consts.h> is only valid for the V6C target"
#endif

#include <stdint.h>

/* =======================================================
 * Row selection codes (sent to port 3 to select a row)
 * Value = ~(1 << row_index) & 0xFF
 * ======================================================= */
#define KEY_CODE_ROW_0      ((uint8_t)(~(1u << 0)))  /* 0xFE */
#define KEY_CODE_ROW_1      ((uint8_t)(~(1u << 1)))  /* 0xFD */
#define KEY_CODE_ROW_2      ((uint8_t)(~(1u << 2)))  /* 0xFB */
#define KEY_CODE_ROW_3      ((uint8_t)(~(1u << 3)))  /* 0xF7 */
#define KEY_CODE_ROW_4      ((uint8_t)(~(1u << 4)))  /* 0xEF */
#define KEY_CODE_ROW_5      ((uint8_t)(~(1u << 5)))  /* 0xDF */
#define KEY_CODE_ROW_6      ((uint8_t)(~(1u << 6)))  /* 0xBF */
#define KEY_CODE_ROW_7      ((uint8_t)(~(1u << 7)))  /* 0x7F */

/* =======================================================
 * Key codes (row 0: special keys)
 * Read from port 2 after selecting the row.
 * Bit = 0 means key is pressed.
 * ======================================================= */
#define KEY_CODE_NO         0xFFu   /* no key pressed */

/* Row 0 key codes */
#define KEY_CODE_TAB        ((uint8_t)(~(1u << 0)))  /* ТАБ — CONTROL_CODE_RETURN */
#define KEY_CODE_ALT        ((uint8_t)(~(1u << 1)))  /* ПС  — CONTROL_CODE_FIRE2  */
#define KEY_CODE_ENTER      ((uint8_t)(~(1u << 2)))  /* ВК  */
#define KEY_CODE_DEL        ((uint8_t)(~(1u << 3)))  /* ЗАБ */
#define KEY_CODE_LEFT       ((uint8_t)(~(1u << 4)))
#define KEY_CODE_UP         ((uint8_t)(~(1u << 5)))
#define KEY_CODE_RIGHT      ((uint8_t)(~(1u << 6)))
#define KEY_CODE_DOWN       ((uint8_t)(~(1u << 7)))

/* Row 7 key codes */
#define KEY_CODE_X          ((uint8_t)(~(1u << 0)))
#define KEY_CODE_Y          ((uint8_t)(~(1u << 1)))
#define KEY_CODE_Z          ((uint8_t)(~(1u << 2)))
#define KEY_CODE_S_BRAKET_L ((uint8_t)(~(1u << 3)))
#define KEY_CODE_BACKSLASH  ((uint8_t)(~(1u << 4)))
#define KEY_CODE_S_BRAKET_R ((uint8_t)(~(1u << 5)))
#define KEY_CODE_CARET      ((uint8_t)(~(1u << 6)))
#define KEY_CODE_SPACE      ((uint8_t)(~(1u << 7)))  /* CONTROL_CODE_FIRE1 */

/* =======================================================
 * Joystick codes
 *
 * Joystick "P"  format: ABxxDULR  (bit = 0 means pressed)
 * Joystick "C"  format: BAxxDULR  (bit = 0 means pressed)
 * Joystick "USPID" format: URDLABxx (bit = 1 means pressed)
 * ======================================================= */
#define JOY_CODE_RIGHT      ((uint8_t)(~(1u << 0)))  /* 0xFE */
#define JOY_CODE_LEFT       ((uint8_t)(~(1u << 1)))  /* 0xFD */
#define JOY_CODE_UP         ((uint8_t)(~(1u << 2)))  /* 0xFB */
#define JOY_CODE_DOWN       ((uint8_t)(~(1u << 3)))  /* 0xF7 */
#define JOY_CODE_FIRE2      ((uint8_t)(~(1u << 6)))  /* 0xBF */
#define JOY_CODE_FIRE1      ((uint8_t)(~(1u << 7)))  /* 0x7F */

/* =======================================================
 * Control action codes
 *
 * Each bit represents one action.  Bit = 1 means the action is active.
 * Stored in action_code (one byte).
 * ======================================================= */
#define CONTROL_CODE_NO         0u

#define CONTROL_CODE_RIGHT      ((uint8_t)(1u << 0))  /* 0x01 */
#define CONTROL_CODE_LEFT       ((uint8_t)(1u << 1))  /* 0x02 */
#define CONTROL_CODE_UP         ((uint8_t)(1u << 2))  /* 0x04 */
#define CONTROL_CODE_DOWN       ((uint8_t)(1u << 3))  /* 0x08 */
#define CONTROL_CODE_RETURN     ((uint8_t)(1u << 4))  /* 0x10 */
#define CONTROL_CODE_KEY_SPACE  ((uint8_t)(1u << 5))  /* 0x20 — always bound to KEY_CODE_SPACE */
#define CONTROL_CODE_FIRE2      ((uint8_t)(1u << 6))  /* 0x40 */
#define CONTROL_CODE_FIRE1      ((uint8_t)(1u << 7))  /* 0x80 */

/* =======================================================
 * Control preset IDs
 * ======================================================= */
#define CONTROL_PRESET_KEYBOARD 0u
#define CONTROL_PRESET_JOYSTICK 1u

#endif /* __V6C_V6C_CONTROLS_CONSTS_H */
