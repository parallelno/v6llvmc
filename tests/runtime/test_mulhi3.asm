; TEST: test_mulhi3
; DESC: Test 16-bit multiply (__mulhi3): HL * DE -> HL (low 16 bits)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 0, 6, 100, 42, 255

    .org 0
    LXI SP, 0xFFFF

    ; Include __mulhi3 implementation
    JMP _test_start

; --- __mulhi3 inlined ---
__mulhi3:
    XCHG
    MOV A, H
    MOV C, L
    LXI H, 0

    MVI B, 8
_mulhi3_p1:
    DAD H
    RLC
    JNC _mulhi3_p1n
    DAD D
_mulhi3_p1n:
    DCR B
    JNZ _mulhi3_p1

    MOV A, C
    MVI B, 8
_mulhi3_p2:
    DAD H
    RLC
    JNC _mulhi3_p2n
    DAD D
_mulhi3_p2n:
    DCR B
    JNZ _mulhi3_p2
    RET

; --- Tests ---
_test_start:
    ; Test 1: 0 * 0 = 0
    LXI H, 0
    LXI D, 0
    CALL __mulhi3
    MOV A, L            ; result low byte
    OUT 0xED            ; expect 0

    ; Test 2: 2 * 3 = 6
    LXI H, 2
    LXI D, 3
    CALL __mulhi3
    MOV A, L
    OUT 0xED            ; expect 6

    ; Test 3: 10 * 10 = 100
    LXI H, 10
    LXI D, 10
    CALL __mulhi3
    MOV A, L
    OUT 0xED            ; expect 100

    ; Test 4: 6 * 7 = 42
    LXI H, 6
    LXI D, 7
    CALL __mulhi3
    MOV A, L
    OUT 0xED            ; expect 42

    ; Test 5: 255 * 1 = 255
    LXI H, 255
    LXI D, 1
    CALL __mulhi3
    MOV A, L
    OUT 0xED            ; expect 255

    HLT
