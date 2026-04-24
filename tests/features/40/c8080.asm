    device zxspectrum48 ; There is no ZX Spectrum, it is needed for the sjasmplus assembler.
    org 100h
__begin:
__entry:
__init:
; 26 void __init() {
; 27     /* Zeroing uninitialized variables */
; 28     asm {

        ld   de, __bss
        xor  a
__init_loop:
        ld   (de), a
        inc  de
        ld   hl, 10000h - __end
        add  hl, de
        jp   nc, __init_loop

; 29         ld   de, __bss
; 30         xor  a
; 31 __init_loop:
; 32         ld   (de), a
; 33         inc  de
; 34         ld   hl, 10000h - __end
; 35         add  hl, de
; 36         jp   nc, __init_loop
; 37     }
; 38 
; 39     /* Init stack */
; 40 #if __has_include(<c8080/initstack.inc>) && !defined(ARCH_CPM_CCP) && !defined(ARCH_CPM_BDOS) && !defined(ARCH_CPM_BIOS)
; 41 #include <c8080/initstack.inc>
; 42 #endif
; 43 
; 44 #ifdef ARCH_CPM_CCP /* CCP remains in memory */
; 45     // clang-format off
; 46     asm {
; 47         pop  de
; 48         ld   a, (7)
; 49         sub  8
; 50         ld   h, a
; 51         ld   l, 0
; 52         ld   sp, hl
; 53         push de
; 54     }
; 55     // clang-format on
; 56 #endif
; 57 
; 58 #ifdef ARCH_CPM_BDOS /* BDOS remains in memory */
; 59     asm {
; 60         ld   a, (7)
; 61         ld   h, a
; 62         ld   l, 0
; 63         ld   sp, hl
; 64         ld   hl, 0
; 65         push hl
; 66     }
; 67 #endif
; 68 
; 69 #ifdef ARCH_CPM_BIOS /* BIOS remains in memory */
; 70 #error TODO
; 71 #endif
; 72 
; 73     main(0, NULL);
	ld hl, 0
	ld (__a_1_main), hl
main:
; 28 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 29     use2(three_i8(0x11, 0x22, 0x33),
	ld a, 17
	ld (__a_1_three_i8), a
	ld a, 34
	ld (__a_2_three_i8), a
	ld a, 51
	call three_i8
	ld (__a_1_use2), a
; 30          four_i8(0x44, 0x55, 0x66, 0x77));
	ld a, 68
	ld (__a_1_four_i8), a
	ld a, 85
	ld (__a_2_four_i8), a
	ld a, 102
	ld (__a_3_four_i8), a
	ld a, 119
	call four_i8
	call use2
; 31     return 0;
	ld hl, 0
	ret
three_i8:
; 10 unsigned char three_i8(unsigned char x, unsigned char y, unsigned char z) {
	ld (__a_3_three_i8), a
; 11     unsigned char a = op1(x);
	ld a, (__a_1_three_i8)
	call op1
	ld (three_i8_a), a
; 12     unsigned char b = op2(y);
	ld a, (__a_2_three_i8)
	call op2
	ld (three_i8_b), a
; 13     unsigned char c = op1(z);
	ld a, (__a_3_three_i8)
	call op1
	ld (three_i8_c), a
; 14     use3(a, b, c);
	ld a, (three_i8_a)
	ld (__a_1_use3), a
	ld a, (three_i8_b)
	ld (__a_2_use3), a
	ld a, (three_i8_c)
	call use3
; 15     return (unsigned char)(a + b + c);
	ld hl, three_i8_a
	ld a, (three_i8_b)
	add (hl)
	ld hl, three_i8_c
	add (hl)
	ret
four_i8:
; 18 unsigned char four_i8(unsigned char x, unsigned char y,
	ld (__a_4_four_i8), a
; 19                       unsigned char z, unsigned char w) {
; 20     unsigned char a = op1(x);
	ld a, (__a_1_four_i8)
	call op1
	ld (four_i8_a), a
; 21     unsigned char b = op2(y);
	ld a, (__a_2_four_i8)
	call op2
	ld (four_i8_b), a
; 22     unsigned char c = op1(z);
	ld a, (__a_3_four_i8)
	call op1
	ld (four_i8_c), a
; 23     unsigned char d = op2(w);
	ld a, (__a_4_four_i8)
	call op2
	ld (four_i8_d), a
; 24     use4(a, b, c, d);
	ld a, (four_i8_a)
	ld (__a_1_use4), a
	ld a, (four_i8_b)
	ld (__a_2_use4), a
	ld a, (four_i8_c)
	ld (__a_3_use4), a
	ld a, (four_i8_d)
	call use4
; 25     return (unsigned char)(a + b + c + d);
	ld hl, four_i8_a
	ld a, (four_i8_b)
	add (hl)
	ld hl, four_i8_c
	add (hl)
	ld hl, four_i8_d
	add (hl)
	ret
__bss:
__static_stack:
	ds 18
__end:
__s___init equ __static_stack + 18
__s_main equ __static_stack + 14
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_three_i8 equ __static_stack + 3
__a_1_three_i8 equ __s_three_i8 + 3
__a_2_three_i8 equ __s_three_i8 + 4
__a_3_three_i8 equ __s_three_i8 + 5
__s_four_i8 equ __static_stack + 4
__a_1_four_i8 equ __s_four_i8 + 4
__a_2_four_i8 equ __s_four_i8 + 5
__a_3_four_i8 equ __s_four_i8 + 6
__a_4_four_i8 equ __s_four_i8 + 7
__s_use2 equ __static_stack + 12
__a_1_use2 equ __s_use2 + 0
__a_2_use2 equ __s_use2 + 1
three_i8_a equ __s_three_i8 + 0
__s_op1 equ __static_stack + 0
__a_1_op1 equ __s_op1 + 0
three_i8_b equ __s_three_i8 + 1
__s_op2 equ __static_stack + 0
__a_1_op2 equ __s_op2 + 0
three_i8_c equ __s_three_i8 + 2
__s_use3 equ __static_stack + 0
__a_1_use3 equ __s_use3 + 0
__a_2_use3 equ __s_use3 + 1
__a_3_use3 equ __s_use3 + 2
four_i8_a equ __s_four_i8 + 0
four_i8_b equ __s_four_i8 + 1
four_i8_c equ __s_four_i8 + 2
four_i8_d equ __s_four_i8 + 3
__s_use4 equ __static_stack + 0
__a_1_use4 equ __s_use4 + 0
__a_2_use4 equ __s_use4 + 1
__a_3_use4 equ __s_use4 + 2
__a_4_use4 equ __s_use4 + 3
    savebin "tests\features\40\c8080.bin", __begin, __bss - __begin
