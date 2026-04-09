; mulhi3.s — 16-bit unsigned multiply: i16 * i16 → i16
;
; __mulhi3: Multiply two 16-bit values, return low 16-bit result.
;
; Calling convention (V6C_CConv):
;   Arg 1 (multiplicand): HL (i16)
;   Arg 2 (multiplier):   DE (i16)
;   Return: HL (i16) = HL * DE (low 16 bits)
;
; Algorithm: Left-shift-and-add.
;   Process multiplier bits from MSB to LSB.
;   For each bit: shift result left, if bit was set add multiplicand.
;   Process high byte then low byte of multiplier (8 iterations each).
;
; Registers: HL = result, DE = multiplicand, A = multiplier byte, B = counter
; Clobbers: A, B, C, D, E, H, L, FLAGS

    .globl __mulhi3
__mulhi3:
    ; Swap: DE = multiplicand, HL = multiplier
    XCHG
    MOV A, H                 ; A = multiplier high byte
    MOV C, L                 ; C = multiplier low byte (saved for pass 2)
    LXI H, 0                ; HL = 0 (result)

    ; Pass 1: process 8 MSBs of multiplier (high byte in A)
    MVI B, 8
_mulhi3_p1:
    DAD H                    ; result <<= 1
    RLC                      ; A <<= 1 (rotate left, bit 7 → carry)
    JNC _mulhi3_p1n
    DAD D                    ; result += multiplicand
_mulhi3_p1n:
    DCR B
    JNZ _mulhi3_p1

    ; Pass 2: process 8 LSBs of multiplier (low byte in C)
    MOV A, C
    MVI B, 8
_mulhi3_p2:
    DAD H                    ; result <<= 1
    RLC                      ; A <<= 1
    JNC _mulhi3_p2n
    DAD D                    ; result += multiplicand
_mulhi3_p2n:
    DCR B
    JNZ _mulhi3_p2

    ; HL = low 16 bits of product
    RET
