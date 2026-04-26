.text
.globl _start
_start:
    LXI SP, __stack_top   ; SP setup
    ; (optional) zero .bss here if any
    CALL main
    HLT