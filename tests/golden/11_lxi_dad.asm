; TEST: lxi_dad
; DESC: LXI 16-bit immediate loads and DAD 16-bit addition
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 18, 52, 18, 52, 1, 0, 240, 0

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: LXI H loads 16-bit value
    LXI H, 0x1234
    MOV A, H
    OUT 0xED            ; expect 18 (0x12)
    MOV A, L
    OUT 0xED            ; expect 52 (0x34)

    ; Test 2: DAD B (HL = HL + BC)
    LXI H, 0x1000
    LXI B, 0x0234
    DAD B               ; HL = 0x1234
    MOV A, H
    OUT 0xED            ; expect 18 (0x12)
    MOV A, L
    OUT 0xED            ; expect 52 (0x34)

    ; Test 3: DAD with 16-bit overflow
    LXI H, 0xFF00
    LXI B, 0x0200
    DAD B               ; HL = 0x10100 & 0xFFFF = 0x0100
    MOV A, H
    OUT 0xED            ; expect 1 (0x01)
    MOV A, L
    OUT 0xED            ; expect 0 (0x00)

    ; Test 4: DAD SP (HL = HL + SP)
    LXI SP, 0xF000
    LXI H, 0x0000
    DAD SP              ; HL = 0xF000
    MOV A, H
    OUT 0xED            ; expect 240 (0xF0)
    MOV A, L
    OUT 0xED            ; expect 0

    LXI SP, 0xFFFF      ; restore SP
    HLT
