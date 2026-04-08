; TEST: logic_ops
; DESC: ANA, ORA, XRA, CMA logical operations
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 15, 255, 85, 170, 136

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: ANI (AND immediate) - mask low nibble
    MVI A, 0xFF
    ANI 0x0F            ; A = 0x0F = 15
    OUT 0xED            ; expect 15

    ; Test 2: ORI (OR immediate) - set all bits
    MVI A, 0xF0
    ORI 0x0F            ; A = 0xFF = 255
    OUT 0xED            ; expect 255

    ; Test 3: XRI (XOR immediate) - invert alternate bits
    MVI A, 0xFF
    XRI 0xAA            ; A = 0x55 = 85
    OUT 0xED            ; expect 85

    ; Test 4: CMA (complement accumulator)
    MVI A, 0x55
    CMA                 ; A = 0xAA = 170
    OUT 0xED            ; expect 170

    ; Test 5: ANA register
    MVI A, 0xCC         ; 0b11001100
    MVI B, 0xAA         ; 0b10101010
    ANA B               ; 0b10001000 = 0x88 = 136
    OUT 0xED            ; expect 136

    HLT
