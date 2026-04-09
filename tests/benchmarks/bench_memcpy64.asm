; TEST: bench_memcpy64
; DESC: Benchmark: memcpy 64-byte block
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1

    .org 0
    LXI SP, 0xFFFF
    JMP _bench_start

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

; --- Benchmark ---
_bench_start:
    ; Copy 64 bytes
    LXI H, _dst
    LXI D, _src
    LXI B, 64
    CALL memcpy

    ; Verify first and last byte
    LXI H, _dst
    MOV A, M
    CPI 0xAA
    JNZ _fail
    LXI H, _dst
    LXI D, 63
    DAD D
    MOV A, M
    CPI 0xAA
    JNZ _fail

    MVI A, 1
    OUT 0xED
    HLT

_fail:
    MVI A, 0
    OUT 0xED
    HLT

; 64-byte source buffer filled with 0xAA
_src:
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA
    .db 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA

; 64-byte destination (zeroed)
_dst:
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
