; TEST: jmp_branch
; DESC: JMP, JZ, JNZ conditional branching
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 2, 3, 4

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: Unconditional JMP
    JMP test1_ok
    MVI A, 0xFF         ; should be skipped
    OUT 0xED
test1_ok:
    MVI A, 1
    OUT 0xED            ; expect 1

    ; Test 2: JZ - should jump when zero flag is set
    MVI A, 0
    ORA A               ; set zero flag (A=0)
    JZ test2_ok
    MVI A, 0xFF         ; should be skipped
    OUT 0xED
test2_ok:
    MVI A, 2
    OUT 0xED            ; expect 2

    ; Test 3: JNZ - should jump when zero flag is NOT set
    MVI A, 5
    ORA A               ; clear zero flag (A!=0)
    JNZ test3_ok
    MVI A, 0xFF         ; should be skipped
    OUT 0xED
test3_ok:
    MVI A, 3
    OUT 0xED            ; expect 3

    ; Test 4: JZ should NOT jump when zero flag is clear
    MVI A, 5
    ORA A               ; zero flag clear
    JZ test4_fail
    MVI A, 4
    OUT 0xED            ; expect 4
    JMP test4_done
test4_fail:
    MVI A, 0xFF
    OUT 0xED
test4_done:

    HLT
