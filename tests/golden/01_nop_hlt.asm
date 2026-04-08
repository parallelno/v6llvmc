; TEST: nop_hlt
; DESC: NOP followed by HLT - verify basic execution and halt
; EXPECT_HALT: yes
; EXPECT_REG: A=00

    .org 0
    NOP
    HLT
