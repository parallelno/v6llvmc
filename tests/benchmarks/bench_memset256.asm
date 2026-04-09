; TEST: bench_memset256
; DESC: Benchmark: memset 256-byte block
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1

    .org 0
    LXI SP, 0xFFFF
    JMP _bench_start

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

; --- Benchmark ---
_bench_start:
    ; Fill 256 bytes with 0x55
    LXI H, _buf
    LXI D, 0x0055       ; E = 0x55
    LXI B, 256
    CALL memset

    ; Verify first and last byte
    LXI H, _buf
    MOV A, M
    CPI 0x55
    JNZ _fail
    LXI H, _buf
    LXI D, 255
    DAD D
    MOV A, M
    CPI 0x55
    JNZ _fail

    MVI A, 1
    OUT 0xED
    HLT

_fail:
    MVI A, 0
    OUT 0xED
    HLT

; 256-byte buffer
_buf:
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    .db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
