; TEST: memory_ops
; DESC: STA/LDA, MOV M, STAX/LDAX, SHLD/LHLD indirect memory access
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 42, 99, 77, 88, 171, 205

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: STA / LDA (direct address)
    MVI A, 42
    STA 0x8000          ; store 42 at address 0x8000
    MVI A, 0            ; clear A
    LDA 0x8000          ; load from 0x8000
    OUT 0xED            ; expect 42

    ; Test 2: MOV M, r / MOV r, M (indirect via HL)
    LXI H, 0x8001
    MVI A, 99
    MOV M, A            ; store 99 at 0x8001
    MVI A, 0            ; clear A
    MOV A, M            ; load from 0x8001
    OUT 0xED            ; expect 99

    ; Test 3: STAX / LDAX via BC
    LXI B, 0x8002
    MVI A, 77
    STAX B              ; store 77 at 0x8002
    MVI A, 0
    LDAX B              ; load from 0x8002
    OUT 0xED            ; expect 77

    ; Test 4: STAX / LDAX via DE
    LXI D, 0x8003
    MVI A, 88
    STAX D
    MVI A, 0
    LDAX D
    OUT 0xED            ; expect 88

    ; Test 5: SHLD / LHLD (store/load HL pair)
    LXI H, 0xABCD
    SHLD 0x8010         ; store L at 0x8010, H at 0x8011
    LXI H, 0x0000      ; clear HL
    LHLD 0x8010         ; load HL from 0x8010
    MOV A, H
    OUT 0xED            ; expect 171 (0xAB)
    MOV A, L
    OUT 0xED            ; expect 205 (0xCD)

    HLT
