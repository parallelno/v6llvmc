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
