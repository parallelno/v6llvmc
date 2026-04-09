; divhi3.s — 16-bit signed division and modulo
;
; __divhi3: Signed 16-bit division.
; __modhi3: Signed 16-bit modulo.
;
; Calling convention (V6C_CConv):
;   Arg 1 (dividend):  HL (i16)
;   Arg 2 (divisor):   DE (i16)
;   Return: HL (i16) = quotient (__divhi3) or remainder (__modhi3)
;
; Algorithm: Convert to unsigned, perform unsigned division, fix signs.
;   Quotient sign: negative if operand signs differ.
;   Remainder sign: same as dividend (C99/C11 truncated division).
;
; Uses __udivmod16 from udivhi3.s.
;
; Clobbers: A, B, C, D, E, H, L, FLAGS

; Helper: negate HL (two's complement)
_neg_hl:
    MOV A, L
    CMA
    MOV L, A
    MOV A, H
    CMA
    MOV H, A
    INX H
    RET

; Helper: negate DE (two's complement)
_neg_de:
    MOV A, E
    CMA
    MOV E, A
    MOV A, D
    CMA
    MOV D, A
    INX D
    RET

; __divhi3: signed division, returns quotient
    .globl __divhi3
__divhi3:
    ; Determine result sign: XOR of input signs
    MOV A, H
    XRA D                    ; bit 7 = sign of result
    PUSH PSW                 ; save result sign on stack

    ; Make dividend positive
    MOV A, H
    ORA A
    JP _divhi3_pos_dividend
    CALL _neg_hl
_divhi3_pos_dividend:

    ; Make divisor positive
    MOV A, D
    ORA A
    JP _divhi3_pos_divisor
    CALL _neg_de
_divhi3_pos_divisor:

    ; Unsigned divide: HL / DE → quotient in HL
    CALL __udivmod16

    ; Fix quotient sign
    POP PSW                  ; A has sign info (bit 7)
    ORA A
    JP _divhi3_done          ; positive → done
    CALL _neg_hl             ; negate quotient
_divhi3_done:
    RET

; __modhi3: signed modulo, returns remainder
    .globl __modhi3
__modhi3:
    ; Remainder has same sign as dividend
    MOV A, H
    PUSH PSW                 ; save dividend sign

    ; Make dividend positive
    ORA A
    JP _modhi3_pos_dividend
    CALL _neg_hl
_modhi3_pos_dividend:

    ; Make divisor positive
    MOV A, D
    ORA A
    JP _modhi3_pos_divisor
    CALL _neg_de
_modhi3_pos_divisor:

    ; Unsigned divide: HL / DE → remainder in BC
    CALL __udivmod16

    ; Move remainder to HL
    MOV H, B
    MOV L, C

    ; Fix remainder sign (same as dividend)
    POP PSW                  ; A has dividend sign (bit 7)
    ORA A
    JP _modhi3_done
    CALL _neg_hl             ; negate remainder
_modhi3_done:
    RET
