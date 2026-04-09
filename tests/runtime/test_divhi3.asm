; TEST: test_divhi3
; DESC: Test signed 16-bit division (__divhi3): HL / DE -> HL
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 3, 253, 0, 255

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

; --- __divhi3 inlined ---
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

__divhi3:
    MOV A, H
    XRA D
    PUSH PSW
    MOV A, H
    ORA A
    JP _divhi3_posd
    CALL _neg_hl
_divhi3_posd:
    MOV A, D
    ORA A
    JP _divhi3_posv
    CALL _neg_de
_divhi3_posv:
    CALL __udivmod16
    POP PSW
    ORA A
    JP _divhi3_done
    CALL _neg_hl
_divhi3_done:
    RET

; --- Tests ---
_test_start:
    ; Test 1: 10 / 3 = 3
    LXI H, 10
    LXI D, 3
    CALL __divhi3
    MOV A, L
    OUT 0xED            ; expect 3

    ; Test 2: -10 / 3 = -3 (truncated toward zero)
    ; -10 = 0xFFF6, result -3 = 0xFFFD, low byte = 0xFD = 253
    LXI H, 0xFFF6
    LXI D, 3
    CALL __divhi3
    MOV A, L
    OUT 0xED            ; expect 253 (0xFD)

    ; Test 3: 0 / 1 = 0
    LXI H, 0
    LXI D, 1
    CALL __divhi3
    MOV A, L
    OUT 0xED            ; expect 0

    ; Test 4: div by zero guard -> 0xFFFF, low byte = 255
    LXI H, 10
    LXI D, 0
    CALL __divhi3
    MOV A, L
    OUT 0xED            ; expect 255 (0xFF from 0xFFFF)

    HLT
