; udivhi3.s — 16-bit unsigned division and modulo
;
; __udivhi3: Unsigned 16-bit division.
; __umodhi3: Unsigned 16-bit modulo.
;
; Calling convention (V6C_CConv):
;   Arg 1 (dividend):  HL (i16)
;   Arg 2 (divisor):   DE (i16)
;   Return: HL (i16) = quotient (__udivhi3) or remainder (__umodhi3)
;
; Algorithm: Restoring division (shift-and-subtract).
;   Process dividend bits from MSB to LSB.
;   Maintain partial remainder in BC.
;   Shift dividend left into remainder; if remainder >= divisor, subtract.
;   After 16 iterations, HL = quotient, BC = remainder.
;
; Division by zero: returns 0xFFFF (quotient) / 0x0000 (remainder).
;
; Clobbers: A, B, C, D, E, H, L, FLAGS

; Internal: __udivmod16 — performs division, returns both quotient and remainder.
; Output: HL = quotient, BC = remainder.
    .globl __udivmod16
__udivmod16:
    ; Check for division by zero
    MOV A, D
    ORA E
    JNZ _ud_start
    ; Division by zero: return 0xFFFF quotient, 0 remainder
    LXI H, 0xFFFF
    LXI B, 0
    RET

_ud_start:
    ; HL = dividend, DE = divisor
    ; BC = remainder (starts at 0)
    LXI B, 0                ; remainder = 0
    PUSH D                   ; save divisor on stack (we need DE for scratch)

    ; We need: HL = dividend (shifted left, quotient bits shifted in)
    ;          BC = remainder
    ;          DE = divisor (on stack, loaded as needed)
    ;          Counter: need somewhere... use stack
    ; Actually, let's keep divisor on stack and use D for counter.

    POP D                    ; DE = divisor (restore, will manage differently)

    ; Register plan:
    ;   HL = dividend/quotient (quotient bits shift in from right)
    ;   BC = remainder
    ;   DE = divisor
    ;   Counter on stack (push/pop per iteration — expensive)
    ;
    ; Better: process in two passes of 8 iterations each.
    ; Use A as temporary, and a clever register scheme.
    ;
    ; Actually: for 16-bit, we can use XTHL to swap HL with stack.
    ; Keep divisor on stack: [SP] = divisor
    ; Use HL for remainder, DE = dividend/quotient.
    ; But DAD isn't useful here; we need subtraction.
    ;
    ; Simplest correct approach for 8080:
    ;   Keep everything as-is, use stack for loop counter.

    MVI A, 16
    PUSH PSW                 ; save counter on stack

_ud_loop:
    ; Shift dividend (HL) left by 1, MSB goes to remainder (BC)
    DAD H                    ; HL <<= 1 (carry = old bit 15)

    ; Shift carry into remainder: BC = BC * 2 + carry
    MOV A, C
    RAL                      ; C <<= 1, carry-in from HL shift
    MOV C, A
    MOV A, B
    RAL                      ; B <<= 1, carry-in from C shift
    MOV B, A

    ; Compare remainder (BC) >= divisor (DE)
    ; BC - DE: if no borrow (carry set after subtraction), BC >= DE
    MOV A, C
    SUB E                    ; A = C - E
    MOV A, B
    SBB D                    ; A = B - D - borrow
    JC _ud_less              ; If borrow: remainder < divisor, skip

    ; remainder >= divisor: subtract and set quotient bit
    MOV A, C
    SUB E
    MOV C, A
    MOV A, B
    SBB D
    MOV B, A
    INX H                    ; Set bit 0 of quotient (shifted in by DAD H earlier, was 0)
    ; Actually, DAD H shifted left, inserting 0 at bit 0. INX H sets it to 1.

_ud_less:
    ; Decrement counter
    POP PSW                  ; A = counter
    DCR A
    PUSH PSW                 ; save counter back
    JNZ _ud_loop

    ; Clean up stack
    POP PSW                  ; remove counter from stack

    ; HL = quotient, BC = remainder
    RET

; __udivhi3: unsigned division, returns quotient
    .globl __udivhi3
__udivhi3:
    CALL __udivmod16
    ; HL = quotient (already in place)
    RET

; __umodhi3: unsigned modulo, returns remainder
    .globl __umodhi3
__umodhi3:
    CALL __udivmod16
    ; BC = remainder, move to HL
    MOV H, B
    MOV L, C
    RET
