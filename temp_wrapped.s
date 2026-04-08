; Wrapper: CALL main, OUT result to 0xED, HLT
; main function binary: MVI A, 0x2A (3E 2A), RET (C9) — starts at address 3
CALL 0x0003
OUT 0xED
HLT
; main:
MVI A, 0x2A
RET
