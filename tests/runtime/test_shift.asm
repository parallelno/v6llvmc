; TEST: test_shift
; DESC: Test 16-bit variable shift routines (__ashlhi3, __lshrhi3, __ashrhi3)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 2, 8, 128, 0, 64, 1, 128, 255

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
    ; Test 1: 1 << 1 = 2
    LXI H, 1
    LXI D, 1
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 2

    ; Test 2: 1 << 3 = 8
    LXI H, 1
    LXI D, 3
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 8

    ; Test 3: 1 << 7 = 128
    LXI H, 1
    LXI D, 7
    CALL __ashlhi3
    MOV A, L
    OUT 0xED            ; expect 128

    ; Test 4: 256 >> 8 (logical) = 1, but as low byte = 0 (256 >> 8 = 1, L = 1)
    ; Actually 256 = 0x0100. 0x0100 >> 8 = 0x0001. L = 0x01... hmm
    ; Let me use: 128 >> 7 = 1, but let's test 0
    ; Test 4: 1 >> 1 (logical) = 0
    LXI H, 1
    LXI D, 1
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 0

    ; Test 5: 128 >> 1 (logical) = 64
    LXI H, 128
    LXI D, 1
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 64

    ; Test 6: 256 >> 8 (logical) = 1
    LXI H, 0x0100
    LXI D, 8
    CALL __lshrhi3
    MOV A, L
    OUT 0xED            ; expect 1

    ; Test 7: -256 >> 1 (arithmetic) = -128 = 0xFF80, L = 0x80 = 128
    LXI H, 0xFF00      ; -256 in i16
    LXI D, 1
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 128 (0x80)

    ; Test 8: -1 >> 8 (arithmetic) = -1 = 0xFFFF, L = 0xFF = 255
    LXI H, 0xFFFF      ; -1 in i16
    LXI D, 8
    CALL __ashrhi3
    MOV A, L
    OUT 0xED            ; expect 255 (0xFF)

    HLT
