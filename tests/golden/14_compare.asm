; TEST: compare
; DESC: CMP/CPI with conditional branches based on comparison result
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 2, 3, 4

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: Equal comparison (CPI sets zero flag)
    MVI A, 42
    CPI 42              ; A == 42: zero flag set, carry clear
    JZ eq_ok
    MVI A, 0xFF
    OUT 0xED
    JMP eq_done
eq_ok:
    MVI A, 1
    OUT 0xED            ; expect 1
eq_done:

    ; Test 2: Less than (CPI sets carry flag)
    MVI A, 10
    CPI 20              ; A < 20: carry set
    JC lt_ok
    MVI A, 0xFF
    OUT 0xED
    JMP lt_done
lt_ok:
    MVI A, 2
    OUT 0xED            ; expect 2
lt_done:

    ; Test 3: Greater than (carry clear, zero clear)
    MVI A, 30
    CPI 20              ; A > 20: carry clear, zero clear
    JNC gt_maybe
    MVI A, 0xFF
    OUT 0xED
    JMP gt_done
gt_maybe:
    JZ gt_fail          ; if zero, it was equal, not greater
    MVI A, 3
    OUT 0xED            ; expect 3
    JMP gt_done
gt_fail:
    MVI A, 0xFF
    OUT 0xED
gt_done:

    ; Test 4: CMP register
    MVI A, 100
    MVI B, 100
    CMP B               ; A == B: zero flag set
    JZ cmp_reg_ok
    MVI A, 0xFF
    OUT 0xED
    JMP cmp_reg_done
cmp_reg_ok:
    MVI A, 4
    OUT 0xED            ; expect 4
cmp_reg_done:

    HLT
