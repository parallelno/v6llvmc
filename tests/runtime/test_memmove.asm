; TEST: test_memmove
; DESC: Test memmove: overlap-safe copy (forward and backward)
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 2, 3, 4, 5, 3, 4, 5, 4, 3, 4, 5

    .org 0
    LXI SP, 0xFFFF
    JMP _test_start

; --- memmove inlined ---
memmove:
    PUSH H
    MOV A, B
    ORA C
    JZ _memmove_done
    MOV A, L
    SUB E
    MOV A, H
    SBB D
    JC _memmove_forward
    ; dst >= src: backward copy
    DAD B
    DCX H
    PUSH H
    MOV H, D
    MOV L, E
    DAD B
    DCX H
    XCHG
    POP H
_memmove_backward:
    MOV A, B
    ORA C
    JZ _memmove_done
    LDAX D
    MOV M, A
    DCX H
    DCX D
    DCX B
    JMP _memmove_backward
_memmove_forward:
    POP H
    PUSH H
_memmove_fwd_loop:
    MOV A, B
    ORA C
    JZ _memmove_done
    LDAX D
    MOV M, A
    INX H
    INX D
    DCX B
    JMP _memmove_fwd_loop
_memmove_done:
    POP H
    RET

; --- Tests ---
_test_start:
    ; Test 1: Non-overlapping copy (5 bytes)
    ; src = _src1 [1,2,3,4,5], dst = _dst1
    LXI H, _dst1
    LXI D, _src1
    LXI B, 5
    CALL memmove
    LXI H, _dst1
    MOV A, M
    OUT 0xED            ; expect 1
    INX H
    MOV A, M
    OUT 0xED            ; expect 2
    INX H
    MOV A, M
    OUT 0xED            ; expect 3
    INX H
    MOV A, M
    OUT 0xED            ; expect 4
    INX H
    MOV A, M
    OUT 0xED            ; expect 5

    ; Test 2: Overlapping forward (dst < src)
    ; buf = [1,2,3,4,5], copy buf[2..4] to buf[0..2] (src=buf+2, dst=buf)
    ; memmove(dst=_buf2, src=_buf2+2, n=3), so [3,4,5] -> positions 0..2
    ; Result: [3,4,5,4,5]
    LXI H, _buf2
    LXI D, _buf2_s      ; src = _buf2 + 2
    LXI B, 3
    CALL memmove
    LXI H, _buf2
    MOV A, M
    OUT 0xED            ; expect 3 (was 1, now 3 from src[0])
    INX H
    MOV A, M
    OUT 0xED            ; expect 4 (was 2, now 4 from src[1])
    INX H
    MOV A, M
    OUT 0xED            ; expect 5 (was 3, now 5 from src[2])
    INX H
    MOV A, M
    OUT 0xED            ; expect 4 (unchanged)

    ; Test 3: Overlapping backward (dst > src)
    ; buf = [3,4,5,6,7], copy buf[0..2] to buf[2..4] (src=buf, dst=buf+2)
    ; memmove(dst=_buf3+2, src=_buf3, n=3)
    ; Without correct backward copy, this would corrupt: [3,4,3,4,3]
    ; With correct backward copy: [3,4,3,4,5]
    LXI H, _buf3_d      ; dst = _buf3 + 2
    LXI D, _buf3        ; src = _buf3
    LXI B, 3
    CALL memmove
    LXI H, _buf3
    INX H
    INX H
    MOV A, M
    OUT 0xED            ; expect 3 (from _buf3[0])
    INX H
    MOV A, M
    OUT 0xED            ; expect 4 (from _buf3[1])
    INX H
    MOV A, M
    OUT 0xED            ; expect 5 (from _buf3[2])

    HLT

_src1:
    .db 1, 2, 3, 4, 5
_dst1:
    .db 0, 0, 0, 0, 0

; _buf2 = [1,2,3,4,5], _buf2_s = _buf2 + 2
_buf2:
    .db 1, 2
_buf2_s:
    .db 3, 4, 5

; _buf3 = [3,4,5,6,7], _buf3_d = _buf3 + 2
_buf3:
    .db 3, 4
_buf3_d:
    .db 5, 6, 7
