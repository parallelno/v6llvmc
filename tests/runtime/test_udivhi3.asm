; TEST: test_udivhi3
; DESC: Test 16-bit unsigned division (__udivhi3) and modulo (__umodhi3)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 3, 1, 0, 255, 2, 1

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

__udivhi3:
    CALL __udivmod16
    RET

__umodhi3:
    CALL __udivmod16
    MOV H, B
    MOV L, C
    RET

; --- Tests ---
_test_start:
    ; Test 1: 10 / 3 = 3
    LXI H, 10
    LXI D, 3
    CALL __udivhi3
    MOV A, L
    OUT 0xED            ; expect 3

    ; Test 2: 10 % 3 = 1
    LXI H, 10
    LXI D, 3
    CALL __umodhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 3: 0 / 5 = 0
    LXI H, 0
    LXI D, 5
    CALL __udivhi3
    MOV A, L
    OUT 0xED            ; expect 0

    ; Test 4: 255 / 1 = 255
    LXI H, 255
    LXI D, 1
    CALL __udivhi3
    MOV A, L
    OUT 0xED            ; expect 255

    ; Test 5: 100 / 50 = 2
    LXI H, 100
    LXI D, 50
    CALL __udivhi3
    MOV A, L
    OUT 0xED            ; expect 2

    ; Test 6: 7 % 3 = 1
    LXI H, 7
    LXI D, 3
    CALL __umodhi3
    MOV A, L
    OUT 0xED            ; expect 1

    HLT
