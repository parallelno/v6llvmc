; TEST: mvi_regs
; DESC: MVI to all general-purpose registers, verify via OUT
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 17, 34, 51, 68, 85, 102, 119

    .org 0
    LXI SP, 0xFFFF

    MVI A, 0x11         ; A = 0x11 = 17
    OUT 0xED

    MVI B, 0x22         ; B = 0x22 = 34
    MOV A, B
    OUT 0xED

    MVI C, 0x33         ; C = 0x33 = 51
    MOV A, C
    OUT 0xED

    MVI D, 0x44         ; D = 0x44 = 68
    MOV A, D
    OUT 0xED

    MVI E, 0x55         ; E = 0x55 = 85
    MOV A, E
    OUT 0xED

    MVI H, 0x66         ; H = 0x66 = 102
    MOV A, H
    OUT 0xED

    MVI L, 0x77         ; L = 0x77 = 119
    MOV A, L
    OUT 0xED

    HLT
