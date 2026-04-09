; TEST: bench_divhi3
; DESC: Benchmark: 1000 divisions using __divhi3
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1

    .org 0
    LXI SP, 0xFFFF
    JMP _bench_start

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

; --- Benchmark ---
_bench_start:
    MVI A, 100
    PUSH PSW

_outer:
    MVI A, 10

_inner:
    PUSH PSW
    LXI H, 10000
    LXI D, 7
    CALL __divhi3
    POP PSW
    DCR A
    JNZ _inner

    POP PSW
    DCR A
    PUSH PSW
    JNZ _outer

    POP PSW

    MVI A, 1
    OUT 0xED

    HLT
