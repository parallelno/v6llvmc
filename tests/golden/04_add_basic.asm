; TEST: add_basic
; DESC: ADD register and ADI immediate, including carry propagation via ADC
; EXPECT_HALT: yes
; EXPECT_OUTPUT: 30, 40, 255, 44, 50

    .org 0
    LXI SP, 0xFFFF

    ; Test 1: ADI immediate
    MVI A, 10
    ADI 20              ; A = 30
    OUT 0xED            ; expect 30

    ; Test 2: ADD register
    MVI A, 25
    MVI B, 15
    ADD B               ; A = 40
    OUT 0xED            ; expect 40

    ; Test 3: ADI to max byte
    MVI A, 200
    ADI 55              ; A = 255
    OUT 0xED            ; expect 255

    ; Test 4: ADI causing carry (overflow wraps)
    MVI A, 200
    ADI 100             ; 300 & 0xFF = 44, carry = 1
    OUT 0xED            ; expect 44

    ; Test 5: ADC (add with carry from previous overflow)
    MVI A, 200
    ADI 100             ; A = 44, carry = 1
    MVI B, 5
    ADC B               ; A = 44 + 5 + 1(carry) = 50
    OUT 0xED            ; expect 50

    HLT
