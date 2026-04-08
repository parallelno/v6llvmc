; TEST: call_ret
; DESC: CALL/RET subroutine mechanism, including nested calls
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 30, 60, 99

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: Simple CALL and RET
    MVI A, 20
    CALL add10          ; A should become 30
    OUT 0xED            ; expect 30

    ; Test 2: Call again with different value
    MVI A, 50
    CALL add10          ; A should become 60
    OUT 0xED            ; expect 60

    ; Test 3: Nested subroutine calls
    CALL nested_outer   ; should return 99 in A
    OUT 0xED            ; expect 99

    HLT

add10:
    ADI 10
    RET

nested_outer:
    MVI A, 90
    CALL add_nine
    RET

add_nine:
    ADI 9
    RET
