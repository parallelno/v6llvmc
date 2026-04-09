; TEST: test_ashlhi3
; DESC: Test 16-bit left shift (__ashlhi3): HL << DE -> HL
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 2, 128, 0, 0

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- __ashlhi3 inlined ---
__ashlhi3:
    MOV A, E
    ANI 0x0F
    JZ _ashl_done
    CPI 16
    JNC _ashl_zero
    MOV E, A
_ashl_loop:
    DAD H
    DCR E
    JNZ _ashl_loop
_ashl_done:
    RET
_ashl_zero:
    LXI H, 0
    RET

; --- Tests ---
_test_start:
    ; Test 1: 1 << 0 = 1
    LXI H, 1
    LXI D, 0
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 2: 1 << 1 = 2
    LXI H, 1
    LXI D, 1
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 2

    ; Test 3: 1 << 7 = 128
    LXI H, 1
    LXI D, 7
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 128

    ; Test 4: 1 << 8 = 256 = 0x0100, L = 0
    LXI H, 1
    LXI D, 8
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 0 (low byte of 0x0100)

    ; Test 5: 1 << 15 = 0x8000, L = 0
    LXI H, 1
    LXI D, 15
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 0 (low byte of 0x8000)

    HLT
