; crt0.s — V6C C runtime startup
;
; Initializes stack pointer, zeroes .bss, calls _main, halts.
; The linker places this at the start address (default 0x0100).
;
; Memory layout (set by linker):
;   __bss_start  — start of .bss section
;   __bss_end    — end of .bss section (exclusive)
;   _main        — user entry point
;
; Calling convention: V6C_CConv
;   Return value of main in A (i8) or HL (i16)

    .globl _start
_start:
    LXI SP, 0xFFFF          ; Set stack to top of RAM

    ; Zero the .bss section
    LXI H, __bss_start
    LXI D, __bss_end
_bss_loop:
    ; Compare HL with DE: if HL >= DE, done
    MOV A, H
    CMP D
    JC _bss_clear            ; H < D → still have bytes
    JNZ _bss_done            ; H > D → done
    MOV A, L
    CMP E
    JNC _bss_done            ; L >= E → done
_bss_clear:
    MVI M, 0                 ; [HL] = 0
    INX H                    ; HL++
    JMP _bss_loop
_bss_done:

    ; Call main
    CALL _main

    ; Halt — return value is in A (i8) or HL (i16)
    HLT
