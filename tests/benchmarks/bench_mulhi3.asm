; TEST: bench_mulhi3
; DESC: Benchmark: 1000 multiplications using __mulhi3
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1

    .org 0
    LXI SP, 0xFFFF
    JMP _bench_start

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

; --- Benchmark ---
_bench_start:
    ; Run 1000 multiplications (outer loop 100 x inner loop 10)
    MVI A, 100
    PUSH PSW            ; outer counter on stack

_outer:
    MVI A, 10           ; inner counter

_inner:
    PUSH PSW            ; save inner counter
    LXI H, 123
    LXI D, 456
    CALL __mulhi3
    POP PSW
    DCR A
    JNZ _inner

    POP PSW             ; outer counter
    DCR A
    PUSH PSW
    JNZ _outer

    POP PSW             ; clean stack

    ; Output 1 = success marker
    MVI A, 1
    OUT 0xED

    HLT
