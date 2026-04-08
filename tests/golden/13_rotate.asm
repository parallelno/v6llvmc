; TEST: rotate
; DESC: RLC, RRC, RAL, RAR bit rotation operations
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 3, 192, 2, 64, 192

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: RLC (rotate left circular)
    ; 0b10000001 -> bit7 goes to bit0 and carry
    MVI A, 0x81         ; 0b10000001 = 129
    RLC                 ; A = 0b00000011 = 3, carry = 1
    OUT 0xED            ; expect 3

    ; Test 2: RRC (rotate right circular)
    ; 0b10000001 -> bit0 goes to bit7 and carry
    MVI A, 0x81         ; 0b10000001
    RRC                 ; A = 0b11000000 = 0xC0 = 192, carry = 1
    OUT 0xED            ; expect 192

    ; Test 3: RAL (rotate left through carry)
    ; First clear carry with ORA A, then rotate
    MVI A, 0
    ORA A               ; clear carry flag
    MVI A, 0x81         ; 0b10000001 (MVI doesn't affect flags)
    RAL                 ; bit7->carry, carry_old(0)->bit0
                        ; A = 0b00000010 = 2, carry = 1
    OUT 0xED            ; expect 2

    ; Test 4: RAR (rotate right through carry)
    ; Clear carry first
    MVI A, 0
    ORA A               ; clear carry
    MVI A, 0x81         ; 0b10000001 (flags unchanged)
    RAR                 ; bit0->carry, carry_old(0)->bit7
                        ; A = 0b01000000 = 64, carry = 1
    OUT 0xED            ; expect 64

    ; Test 5: Double RLC (shift left by 2 with wrap)
    MVI A, 0x30         ; 0b00110000 = 48
    RLC                 ; 0b01100000 = 96
    RLC                 ; 0b11000000 = 192
    OUT 0xED            ; expect 192

    HLT
