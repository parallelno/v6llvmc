; mulsi3.s — 16×16→32 unsigned multiply
;
; __mulsi3: Multiply two 16-bit values, return full 32-bit result.
;
; Calling convention (V6C_CConv):
;   Arg 1 (multiplicand): HL (i16)
;   Arg 2 (multiplier):   DE (i16)
;   Return: DE:HL (i32) — DE = high 16, HL = low 16
;
; Algorithm: Right-shift multiply with 32-bit accumulator.
;   [HIGH:LOW] where LOW starts as the multiplier.
;   HIGH = 0. Multiplicand in DE.
;   Loop 16 times:
;     Test LOW bit 0 (next multiplier bit)
;     If set: HIGH += multiplicand
;     Right-shift [HIGH:LOW] by 1
;   After 16 iterations, [HIGH:LOW] = product.
;
; Register usage:
;   HL = LOW half of accumulator (and multiplier, shifted out)
;   [SP] = HIGH half of accumulator (accessed via XTHL)
;   DE = multiplicand (constant)
;   B = loop counter
;
; Clobbers: A, B, D, E, H, L, FLAGS

    .globl __mulsi3
__mulsi3:
    ; Setup: swap so HL=multiplier, DE=multiplicand
    XCHG                     ; HL = multiplier, DE = multiplicand
    LXI B, 0
    PUSH B                   ; [SP] = 0x0000 (result HIGH)

    MVI B, 16                ; 16 iterations

_ms3_loop:
    ; Test bit 0 of L (next multiplier bit)
    MOV A, L
    RRC                      ; bit 0 → carry (A rotated but NOT stored back)

    ; Access HIGH half via XTHL
    XTHL                     ; HL = HIGH, [SP] = LOW

    JNC _ms3_noadd
    DAD D                    ; HIGH += multiplicand (carry = overflow)
    JMP _ms3_shift
_ms3_noadd:
    ORA A                    ; clear carry (no add → no overflow)
_ms3_shift:
    ; Shift HIGH right by 1 (carry-in = overflow from add or 0)
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    ; carry-out = LSB of HIGH → becomes MSB of LOW

    ; Swap back to access LOW
    XTHL                     ; HL = LOW, [SP] = shifted HIGH

    ; Shift LOW right by 1 (carry-in = LSB of HIGH)
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    ; carry-out = old LOW LSB (discarded — already consumed as multiplier bit)

    DCR B
    JNZ _ms3_loop

    ; HL = result LOW, [SP] = result HIGH
    POP D                    ; DE = result HIGH
    ; Output: DE:HL = 32-bit product
    RET
