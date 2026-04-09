; TEST: test_umodhi3
; DESC: Test unsigned 16-bit modulo (__umodhi3)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 255, 1

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

__umodhi3:
    CALL __udivmod16
    MOV H, B
    MOV L, C
    RET

; --- Tests ---
_test_start:
    ; Test 1: 0xFFFF % 256 = 255
    ; 65535 % 256 = 255
    LXI H, 0xFFFF
    LXI D, 0x0100
    CALL __umodhi3
    MOV A, L
    OUT 0xED            ; expect 255

    ; Test 2: 10 % 3 = 1
    LXI H, 10
    LXI D, 3
    CALL __umodhi3
    MOV A, L
    OUT 0xED            ; expect 1

    HLT
