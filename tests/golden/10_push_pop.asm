; TEST: push_pop
; DESC: PUSH/POP register pairs, verify stack LIFO ordering
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 18, 52, 171, 205, 51, 68, 17, 34

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: Push BC, clobber, Pop BC - verify preserved
    MVI B, 0x12
    MVI C, 0x34
    PUSH B              ; push BC = 0x1234
    MVI B, 0xFF
    MVI C, 0xFF
    POP B               ; restore BC
    MOV A, B
    OUT 0xED            ; expect 18 (0x12)
    MOV A, C
    OUT 0xED            ; expect 52 (0x34)

    ; Test 2: Push DE, clobber, Pop DE - verify preserved
    MVI D, 0xAB
    MVI E, 0xCD
    PUSH D
    MVI D, 0
    MVI E, 0
    POP D
    MOV A, D
    OUT 0xED            ; expect 171 (0xAB)
    MOV A, E
    OUT 0xED            ; expect 205 (0xCD)

    ; Test 3: Multiple push/pop - LIFO ordering
    MVI B, 0x11
    MVI C, 0x22
    MVI D, 0x33
    MVI E, 0x44
    PUSH B              ; push 0x1122
    PUSH D              ; push 0x3344
    POP B               ; BC = 0x3344 (last pushed = first popped)
    POP D               ; DE = 0x1122 (first pushed = last popped)
    MOV A, B
    OUT 0xED            ; expect 51 (0x33)
    MOV A, C
    OUT 0xED            ; expect 68 (0x44)
    MOV A, D
    OUT 0xED            ; expect 17 (0x11)
    MOV A, E
    OUT 0xED            ; expect 34 (0x22)

    HLT
