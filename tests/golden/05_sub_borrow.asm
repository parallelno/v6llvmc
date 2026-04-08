; TEST: sub_borrow
; DESC: SUB, SUI, SBB with borrow/carry propagation
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 30, 63, 246, 242

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: simple SUI
    MVI A, 50
    SUI 20              ; A = 30
    OUT 0xED            ; expect 30

    ; Test 2: SUB register
    MVI A, 100
    MVI B, 37
    SUB B               ; A = 63
    OUT 0xED            ; expect 63

    ; Test 3: SUI causing borrow (underflow wraps)
    MVI A, 10
    SUI 20              ; A = (10 - 20) & 0xFF = 246, carry = 1
    OUT 0xED            ; expect 246

    ; Test 4: SBB (subtract with borrow from previous underflow)
    MVI A, 10
    SUI 20              ; A = 246, carry = 1
    MVI B, 3
    SBB B               ; A = 246 - 3 - 1(carry) = 242
    OUT 0xED            ; expect 242

    HLT
