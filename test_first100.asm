; V6C Encoding Validation Test
; Assemble with v6asm and verify opcode bytes against TableGen definitions.
; Each instruction on a separate line with its expected opcode byte(s).

; === Miscellaneous ===
    NOP             ; Expected: 0x00
    HLT             ; Expected: 0x76

; === Data Move: MOV r,r (01_DDD_SSS) ===
    MOV A, A        ; Expected: 0x7F (01_111_111)
    MOV A, B        ; Expected: 0x78 (01_111_000)
    MOV B, A        ; Expected: 0x47 (01_000_111)
    MOV B, C        ; Expected: 0x41 (01_000_001)
    MOV C, D        ; Expected: 0x4A (01_001_010)
    MOV D, E        ; Expected: 0x53 (01_010_011)
    MOV E, H        ; Expected: 0x5C (01_011_100)
    MOV H, L        ; Expected: 0x65 (01_100_101)
    MOV L, A        ; Expected: 0x6F (01_101_111)

; === Data Move: MOV r,M / MOV M,r ===
    MOV A, M        ; Expected: 0x7E (01_111_110)
    MOV B, M        ; Expected: 0x46 (01_000_110)
    MOV M, A        ; Expected: 0x77 (01_110_111)
    MOV M, B        ; Expected: 0x70 (01_110_000)

; === Data Move: MVI ===
    MVI A, 42h      ; Expected: 0x3E 0x42
    MVI B, 00h      ; Expected: 0x06 0x00
    MVI C, FFh      ; Expected: 0x0E 0xFF
    MVI D, 10h      ; Expected: 0x16 0x10
    MVI E, 20h      ; Expected: 0x1E 0x20
    MVI H, 30h      ; Expected: 0x26 0x30
    MVI L, 40h      ; Expected: 0x2E 0x40
    MVI M, 55h      ; Expected: 0x36 0x55

; === Data Move: LDA, STA ===
    LDA 1234h       ; Expected: 0x3A 0x34 0x12
    STA 5678h       ; Expected: 0x32 0x78 0x56

; === Data Move: LDAX, STAX ===
    LDAX B          ; Expected: 0x0A
    LDAX D          ; Expected: 0x1A
    STAX B          ; Expected: 0x02
    STAX D          ; Expected: 0x12

; === Data Move: LHLD, SHLD ===
    LHLD 1234h      ; Expected: 0x2A 0x34 0x12
    SHLD 5678h      ; Expected: 0x22 0x78 0x56

; === Data Move: LXI ===
    LXI B, 1234h    ; Expected: 0x01 0x34 0x12
    LXI D, 5678h    ; Expected: 0x11 0x78 0x56
    LXI H, 9ABCh    ; Expected: 0x21 0xBC 0x9A
    LXI SP, DEF0h   ; Expected: 0x31 0xF0 0xDE

; === Data Move: XCHG ===
    XCHG            ; Expected: 0xEB

; === Stack: PUSH, POP ===
    PUSH B          ; Expected: 0xC5
    PUSH D          ; Expected: 0xD5
    PUSH H          ; Expected: 0xE5
    PUSH PSW        ; Expected: 0xF5
    POP B           ; Expected: 0xC1
    POP D           ; Expected: 0xD1
    POP H           ; Expected: 0xE1
    POP PSW         ; Expected: 0xF1

; === Stack: SPHL, XTHL ===
    SPHL            ; Expected: 0xF9
    XTHL            ; Expected: 0xE3

; === ALU 8-bit register: ADD, ADC, SUB, SBB, ANA, XRA, ORA, CMP ===
    ADD A           ; Expected: 0x87 (10_000_111)
    ADD B           ; Expected: 0x80 (10_000_000)
    ADC A           ; Expected: 0x8F
    ADC B           ; Expected: 0x88
    SUB A           ; Expected: 0x97
    SUB B           ; Expected: 0x90
    SBB A           ; Expected: 0x9F
    SBB B           ; Expected: 0x98
    ANA A           ; Expected: 0xA7
    ANA B           ; Expected: 0xA0
    XRA A           ; Expected: 0xAF
    XRA B           ; Expected: 0xA8
    ORA A           ; Expected: 0xB7
    ORA B           ; Expected: 0xB0
    CMP A           ; Expected: 0xBF
    CMP B           ; Expected: 0xB8

; === ALU 8-bit memory ===
    ADD M           ; Expected: 0x86
    ADC M           ; Expected: 0x8E
    SUB M           ; Expected: 0x96
    SBB M           ; Expected: 0x9E
    ANA M           ; Expected: 0xA6
    XRA M           ; Expected: 0xAE
    ORA M           ; Expected: 0xB6
    CMP M           ; Expected: 0xBE

