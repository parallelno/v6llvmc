; TEST: test_lshrhi3
; DESC: Test 16-bit logical right shift (__lshrhi3): HL >> DE -> HL
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 128, 64, 1, 0, 1

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- __lshrhi3 inlined ---
__lshrhi3:
    MOV A, E
    ANI 0x0F
    JZ _lshr_done
    CPI 16
    JNC _lshr_zero
    MOV E, A
_lshr_loop:
    ORA A
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    DCR E
    JNZ _lshr_loop
_lshr_done:
    RET
_lshr_zero:
    LXI H, 0
    RET

; --- Tests ---
_test_start:
    ; Test 1: 128 >> 0 = 128
    LXI H, 128
    LXI D, 0
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 128

    ; Test 2: 128 >> 1 = 64
    LXI H, 128
    LXI D, 1
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 64

    ; Test 3: 128 >> 7 = 1
    LXI H, 128
    LXI D, 7
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 4: 128 >> 8 = 0
    LXI H, 128
    LXI D, 8
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 0

    ; Test 5: 0x8000 >> 15 = 1
    LXI H, 0x8000
    LXI D, 15
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 1

    HLT
