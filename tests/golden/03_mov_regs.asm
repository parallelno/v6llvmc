; TEST: mov_regs
; DESC: Chain MOV operations between all registers, verify propagation
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 42, 42, 42, 42, 42, 42

    .org 0
    LXI SP, 0xFFFF

    MVI A, 42
    MOV B, A            ; B = 42
    MOV C, B            ; C = 42
    MOV D, C            ; D = 42
    MOV E, D            ; E = 42
    MOV H, E            ; H = 42
    MOV L, H            ; L = 42

    ; Output each register to verify
    MOV A, B
    OUT 0xED            ; expect 42
    MOV A, C
    OUT 0xED            ; expect 42
    MOV A, D
    OUT 0xED            ; expect 42
    MOV A, E
    OUT 0xED            ; expect 42
    MOV A, H
    OUT 0xED            ; expect 42
    MOV A, L
    OUT 0xED            ; expect 42

    HLT
