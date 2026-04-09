; TEST: test_memcpy
; DESC: Test memcpy: copy N bytes from source to destination
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 0, 1, 2, 3, 4

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- memcpy inlined ---
memcpy:
    PUSH H
_memcpy_loop:
    MOV A, B
    ORA C
    JZ _memcpy_done
    LDAX D
    MOV M, A
    INX H
    INX D
    DCX B
    JMP _memcpy_loop
_memcpy_done:
    POP H
    RET

; --- Test data ---
_src_data:
    .db 0, 1, 2, 3, 4

; --- Tests ---
_test_start:
    ; Copy 5 bytes from _src_data to _dst_buf
    LXI H, _dst_buf         ; dst
    LXI D, _src_data         ; src
    LXI B, 5                ; count
    CALL memcpy

    ; Verify destination contents
    LXI H, _dst_buf
    MOV A, M
    OUT 0xED                 ; expect 0
    INX H
    MOV A, M
    OUT 0xED                 ; expect 1
    INX H
    MOV A, M
    OUT 0xED                 ; expect 2
    INX H
    MOV A, M
    OUT 0xED                 ; expect 3
    INX H
    MOV A, M
    OUT 0xED                 ; expect 4

    HLT

; Destination buffer (uninitialized, at end of program)
_dst_buf:
    .db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
