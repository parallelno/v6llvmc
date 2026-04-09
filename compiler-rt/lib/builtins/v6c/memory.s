; memory.s — Memory operation routines
;
; memcpy:  Copy N bytes from source to destination (non-overlapping).
; memset:  Fill N bytes with a value.
; memmove: Copy N bytes, handling overlap correctly.
;
; Calling convention (V6C_CConv):
;   memcpy(dst, src, n):  HL=dst(i16), DE=src(i16), BC=n(i16). Returns HL=dst.
;   memset(dst, val, n):  HL=dst(i16), DE=val(i16, low byte E used), BC=n(i16). Returns HL=dst.
;   memmove(dst, src, n): HL=dst(i16), DE=src(i16), BC=n(i16). Returns HL=dst.
;
; Clobbers: A, B, C, D, E, H, L, FLAGS

; --- memcpy ---
    .globl memcpy
memcpy:
    ; HL = dst, DE = src, BC = count
    ; Save dst for return value
    PUSH H

_memcpy_loop:
    ; Check count == 0
    MOV A, B
    ORA C
    JZ _memcpy_done

    ; Copy one byte: [dst] = [src]
    LDAX D                   ; A = [src]
    MOV M, A                 ; [dst] = A
    INX H                    ; dst++
    INX D                    ; src++
    DCX B                    ; count--
    JMP _memcpy_loop

_memcpy_done:
    POP H                    ; HL = original dst (return value)
    RET

; --- memset ---
    .globl memset
memset:
    ; HL = dst, DE = val (E = byte value), BC = count
    ; Save dst for return value
    PUSH H

_memset_loop:
    MOV A, B
    ORA C
    JZ _memset_done

    MOV M, E                 ; [dst] = val
    INX H                    ; dst++
    DCX B                    ; count--
    JMP _memset_loop

_memset_done:
    POP H                    ; HL = original dst
    RET

; --- memmove ---
    .globl memmove
memmove:
    ; HL = dst, DE = src, BC = count
    ; If dst < src or dst >= src+count: forward copy (same as memcpy)
    ; If dst > src and dst < src+count: backward copy

    ; Save dst for return value
    PUSH H

    ; Check count == 0
    MOV A, B
    ORA C
    JZ _memmove_done

    ; Compare dst (HL) vs src (DE)
    ; If dst <= src: forward copy is safe
    MOV A, L
    SUB E
    MOV A, H
    SBB D                    ; carry set if HL < DE
    JC _memmove_forward      ; dst < src: forward

    ; dst >= src: need backward copy
    ; Compute end addresses: dst + count - 1, src + count - 1
    ; Move HL to dst+count-1, DE to src+count-1
    DAD B                    ; HL = dst + count
    DCX H                    ; HL = dst + count - 1
    PUSH H                   ; save dst_end

    ; DE = src + count - 1
    MOV H, D
    MOV L, E                 ; HL = src
    DAD B                    ; HL = src + count
    DCX H                    ; HL = src + count - 1
    XCHG                     ; DE = src_end, HL = ???
    POP H                    ; HL = dst_end

_memmove_backward:
    MOV A, B
    ORA C
    JZ _memmove_done

    ; Copy one byte backward: [dst_end] = [src_end]
    LDAX D                   ; A = [src_end]
    MOV M, A                 ; [dst_end] = A
    DCX H                    ; dst_end--
    DCX D                    ; src_end--
    DCX B                    ; count--
    JMP _memmove_backward

_memmove_forward:
    ; Forward copy (HL=dst already correct from initial, DE=src)
    ; But HL was modified by the comparison; reload from stack
    POP H                    ; get original dst from push at start
    PUSH H                   ; re-push for return value

_memmove_fwd_loop:
    MOV A, B
    ORA C
    JZ _memmove_done

    LDAX D                   ; A = [src]
    MOV M, A                 ; [dst] = A
    INX H                    ; dst++
    INX D                    ; src++
    DCX B                    ; count--
    JMP _memmove_fwd_loop

_memmove_done:
    POP H                    ; HL = original dst
    RET
