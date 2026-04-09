; shift.s — 16-bit variable-count shift routines
;
; __ashlhi3: Logical/arithmetic left shift i16 by variable amount.
; __lshrhi3: Logical right shift i16 by variable amount.
; __ashrhi3: Arithmetic right shift i16 by variable amount.
;
; Calling convention (V6C_CConv):
;   Arg 1 (value): HL (i16)
;   Arg 2 (count): DE (i16) — only low byte (E) used
;   Return: HL (i16) = shifted result
;
; Shift counts >= 16 produce 0 (logical) or sign-fill (arithmetic).
;
; Clobbers: A, D, E, H, L, FLAGS

; __ashlhi3: HL <<= E (logical left shift)
    .globl __ashlhi3
__ashlhi3:
    MOV A, E
    ANI 0x0F                 ; mask to 0-15 (higher shifts → 0)
    JZ _ashl_done
    CPI 16
    JNC _ashl_zero           ; count >= 16 → result is 0

    MOV E, A                 ; E = masked count
_ashl_loop:
    DAD H                    ; HL <<= 1
    DCR E
    JNZ _ashl_loop
_ashl_done:
    RET
_ashl_zero:
    LXI H, 0
    RET

; __lshrhi3: HL >>= E (logical right shift)
    .globl __lshrhi3
__lshrhi3:
    MOV A, E
    ANI 0x0F
    JZ _lshr_done
    CPI 16
    JNC _lshr_zero

    MOV E, A
_lshr_loop:
    ; Shift HL right by 1: H >> 1 (0 → MSB), carry to L
    ORA A                    ; clear carry (0 shifts into MSB)
    MOV A, H
    RAR                      ; H >>= 1 (0 → bit 7)
    MOV H, A
    MOV A, L
    RAR                      ; L >>= 1 (H bit 0 → L bit 7)
    MOV L, A

    DCR E
    JNZ _lshr_loop
_lshr_done:
    RET
_lshr_zero:
    LXI H, 0
    RET

; __ashrhi3: HL >>= E (arithmetic right shift, preserves sign)
    .globl __ashrhi3
__ashrhi3:
    MOV A, E
    ANI 0x0F
    JZ _ashr_done
    CPI 16
    JNC _ashr_fill

    MOV E, A
_ashr_loop:
    ; Arithmetic right shift: replicate sign bit
    MOV A, H
    RAL                      ; bit 7 of H → carry (sign bit)
    MOV A, H
    RAR                      ; H >>= 1, sign bit stays (carry in = sign)
    MOV H, A
    MOV A, L
    RAR                      ; L >>= 1, H bit 0 → L bit 7
    MOV L, A

    DCR E
    JNZ _ashr_loop
_ashr_done:
    RET
_ashr_fill:
    ; count >= 16: fill with sign bit
    MOV A, H
    RAL                      ; sign → carry
    SBB A                    ; A = -1 if sign=1, 0 if sign=0
    MOV H, A
    MOV L, A
    RET
