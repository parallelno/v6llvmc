; TEST: inr_dcr
; DESC: INR and DCR on various registers, including overflow/underflow
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 1, 0, 9, 255, 103

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: INR from 0
    MVI B, 0
    INR B               ; B = 1
    MOV A, B
    OUT 0xED            ; expect 1

    ; Test 2: INR overflow 255 -> 0
    MVI B, 255
    INR B               ; B = 0
    MOV A, B
    OUT 0xED            ; expect 0

    ; Test 3: DCR from 10
    MVI C, 10
    DCR C               ; C = 9
    MOV A, C
    OUT 0xED            ; expect 9

    ; Test 4: DCR underflow 0 -> 255
    MVI D, 0
    DCR D               ; D = 255
    MOV A, D
    OUT 0xED            ; expect 255

    ; Test 5: Multiple INR
    MVI E, 100
    INR E
    INR E
    INR E               ; E = 103
    MOV A, E
    OUT 0xED            ; expect 103

    HLT
