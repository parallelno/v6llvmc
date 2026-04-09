; TEST: test_mulsi3
; DESC: Test 16x16->32 multiply (__mulsi3): HL * DE -> DE:HL (32-bit)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 0, 0, 1, 0, 0, 1, 232, 3, 255, 255, 0, 1

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- __mulsi3 inlined ---
__mulsi3:
    XCHG
    LXI B, 0
    PUSH B
    MVI B, 16
_ms3_loop:
    MOV A, L
    RRC
    XTHL
    JNC _ms3_noadd
    DAD D
    JMP _ms3_shift
_ms3_noadd:
    ORA A
_ms3_shift:
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    XTHL
    MOV A, H
    RAR
    MOV H, A
    MOV A, L
    RAR
    MOV L, A
    DCR B
    JNZ _ms3_loop
    POP D
    RET

; --- Tests ---
_test_start:
    ; Test 1: 0 * 0 = 0x00000000
    LXI H, 0
    LXI D, 0
    CALL __mulsi3
    ; DE:HL = result. Output L, H, E, D
    MOV A, L
    OUT 0xED            ; expect 0 (low byte)
    MOV A, H
    OUT 0xED            ; expect 0

    ; Test 2: 1 * 1 = 0x00000001
    LXI H, 1
    LXI D, 1
    CALL __mulsi3
    MOV A, L
    OUT 0xED            ; expect 1
    MOV A, H
    OUT 0xED            ; expect 0

    ; Test 3: 256 * 1 = 0x00000100
    LXI H, 0x0100
    LXI D, 1
    CALL __mulsi3
    MOV A, L
    OUT 0xED            ; expect 0 (low byte of 0x0100)
    MOV A, H
    OUT 0xED            ; expect 1

    ; Test 4: 100 * 10 = 1000 = 0x000003E8
    LXI H, 100
    LXI D, 10
    CALL __mulsi3
    MOV A, L
    OUT 0xED            ; expect 0xE8 = 232
    MOV A, H
    OUT 0xED            ; expect 0x03 = 3

    ; Test 5: 0xFFFF * 1 = 0x0000FFFF
    LXI H, 0xFFFF
    LXI D, 1
    CALL __mulsi3
    MOV A, L
    OUT 0xED            ; expect 0xFF = 255
    MOV A, H
    OUT 0xED            ; expect 0xFF = 255

    ; Test 6: 0x0100 * 0x0100 = 0x00010000 (=65536)
    ; DE:HL = 0x0001:0x0000
    LXI H, 0x0100
    LXI D, 0x0100
    CALL __mulsi3
    MOV A, L
    OUT 0xED            ; expect 0 (low word low byte)
    MOV A, E
    OUT 0xED            ; expect 1 (high word low byte)

    HLT
