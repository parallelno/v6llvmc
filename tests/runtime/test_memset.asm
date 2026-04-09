; TEST: test_memset
; DESC: Test memset: fill N bytes with a value
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 0, 0, 0, 170, 170, 170, 255

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- memset inlined ---
memset:
    PUSH H
_memset_loop:
    MOV A, B
    ORA C
    JZ _memset_done
    MOV M, E
    INX H
    DCX B
    JMP _memset_loop
_memset_done:
    POP H
    RET

; --- Tests ---
_test_start:
    ; Test 1: memset with 0, 3 bytes
    LXI H, _buf1
    LXI D, 0            ; val = 0 (E = 0)
    LXI B, 3
    CALL memset
    ; Verify
    LXI H, _buf1
    MOV A, M
    OUT 0xED            ; expect 0
    INX H
    MOV A, M
    OUT 0xED            ; expect 0
    INX H
    MOV A, M
    OUT 0xED            ; expect 0

    ; Test 2: memset with 0xAA, 3 bytes
    LXI H, _buf2
    LXI D, 0x00AA       ; val = 0xAA (E = 0xAA)
    LXI B, 3
    CALL memset
    ; Verify
    LXI H, _buf2
    MOV A, M
    OUT 0xED            ; expect 170 (0xAA)
    INX H
    MOV A, M
    OUT 0xED            ; expect 170
    INX H
    MOV A, M
    OUT 0xED            ; expect 170

    ; Test 3: memset 0 bytes (no-op) — verify buffer unchanged
    LXI H, _buf3
    MVI M, 0xFF         ; pre-fill
    LXI H, _buf3
    LXI D, 0x0055       ; val = 0x55
    LXI B, 0            ; count = 0
    CALL memset
    LXI H, _buf3
    MOV A, M
    OUT 0xED            ; expect 255 (unchanged)

    HLT

_buf1:
    .db 0xFF, 0xFF, 0xFF
_buf2:
    .db 0xFF, 0xFF, 0xFF
_buf3:
    .db 0xFF
