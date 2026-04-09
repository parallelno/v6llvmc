; TEST: test_modhi3
; DESC: Test signed 16-bit modulo (__modhi3): HL % DE -> HL
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 255, 0

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- __udivmod16 inlined ---
__udivmod16:
    MOV A, D
    ORA E
    JNZ _ud_start
    LXI H, 0xFFFF
    LXI B, 0
    RET
_ud_start:
    LXI B, 0
    MVI A, 16
    PUSH PSW
_ud_loop:
    DAD H
    MOV A, C
    RAL
    MOV C, A
    MOV A, B
    RAL
    MOV B, A
    MOV A, C
    SUB E
    MOV A, B
    SBB D
    JC _ud_less
    MOV A, C
    SUB E
    MOV C, A
    MOV A, B
    SBB D
    MOV B, A
    INX H
_ud_less:
    POP PSW
    DCR A
    PUSH PSW
    JNZ _ud_loop
    POP PSW
    RET

; --- helpers + __modhi3 inlined ---
_neg_hl:
    MOV A, L
    CMA
    MOV L, A
    MOV A, H
    CMA
    MOV H, A
    INX H
    RET

_neg_de:
    MOV A, E
    CMA
    MOV E, A
    MOV A, D
    CMA
    MOV D, A
    INX D
    RET

__modhi3:
    MOV A, H
    PUSH PSW
    ORA A
    JP _modhi3_posd
    CALL _neg_hl
_modhi3_posd:
    MOV A, D
    ORA A
    JP _modhi3_posv
    CALL _neg_de
_modhi3_posv:
    CALL __udivmod16
    MOV H, B
    MOV L, C
    POP PSW
    ORA A
    JP _modhi3_done
    CALL _neg_hl
_modhi3_done:
    RET

; --- Tests ---
_test_start:
    ; Test 1: 10 % 3 = 1
    LXI H, 10
    LXI D, 3
    CALL __modhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 2: -10 % 3 = -1 (C99 truncated: remainder has same sign as dividend)
    ; -10 = 0xFFF6, -1 = 0xFFFF, low byte = 0xFF = 255
    LXI H, 0xFFF6
    LXI D, 3
    CALL __modhi3
    MOV A, L
    OUT 0xED            ; expect 255 (0xFF = -1)

    ; Test 3: 7 % 1 = 0
    LXI H, 7
    LXI D, 1
    CALL __modhi3
    MOV A, L
    OUT 0xED            ; expect 0

    HLT
