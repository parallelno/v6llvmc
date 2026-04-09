; TEST: test_ashrhi3
; DESC: Test 16-bit arithmetic right shift (__ashrhi3): HL >> DE -> HL (sign-preserving)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 64, 1, 128, 255, 255

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- __ashrhi3 inlined ---
__ashrhi3:
    MOV A, E
    ANI 0x0F
    JZ _ashr_done
    CPI 16
    JNC _ashr_fill
    MOV E, A
_ashr_loop:
    MOV A, H
    RAL
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    DCR E
    JNZ _ashr_loop
_ashr_done:
    RET
_ashr_fill:
    MOV A, H
    RAL
    SBB A
    MOV H, A
    MOV L, A
    RET

; --- Tests ---
_test_start:
    ; Test 1: 128 >> 1 (positive) = 64
    LXI H, 128
    LXI D, 1
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 64

    ; Test 2: 256 >> 8 (positive) = 1
    LXI H, 0x0100
    LXI D, 8
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 3: -256 >> 1 (negative) = -128 = 0xFF80, L = 0x80 = 128
    LXI H, 0xFF00      ; -256
    LXI D, 1
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 128 (0x80)

    ; Test 4: -1 >> 8 = -1 = 0xFFFF, L = 0xFF = 255
    LXI H, 0xFFFF      ; -1
    LXI D, 8
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 255 (0xFF)

    ; Test 5: -1 >> 15 = -1 = 0xFFFF, L = 0xFF = 255
    LXI H, 0xFFFF
    LXI D, 15
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 255 (0xFF)

    HLT
