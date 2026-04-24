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
; 18 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 19     many_i8(0x11, 0x22, 0x33, 0x44, 0x55);
	ld a, 17
	ld (__a_1_many_i8), a
	ld a, 34
	ld (__a_2_many_i8), a
	ld a, 51
	ld (__a_3_many_i8), a
	ld a, 68
	ld (__a_4_many_i8), a
	ld a, 85
	call many_i8
; 20     return 0;
	ld hl, 0
	ret
many_i8:
; 7 unsigned char many_i8(unsigned char a, unsigned char b, unsigned char c,
	ld (__a_5_many_i8), a
; 8                       unsigned char d, unsigned char e) {
; 9     unsigned char x1 = op(a);
	ld a, (__a_1_many_i8)
	call op
	ld (many_i8_x1), a
; 10     unsigned char x2 = op(b);
	ld a, (__a_2_many_i8)
	call op
	ld (many_i8_x2), a
; 11     unsigned char x3 = op(c);
	ld a, (__a_3_many_i8)
	call op
	ld (many_i8_x3), a
; 12     unsigned char x4 = op(d);
	ld a, (__a_4_many_i8)
	call op
	ld (many_i8_x4), a
; 13     unsigned char x5 = op(e);
	ld a, (__a_5_many_i8)
	call op
	ld (many_i8_x5), a
; 14     use5(x1, x2, x3, x4, x5);
	ld a, (many_i8_x1)
	ld (__a_1_use5), a
	ld a, (many_i8_x2)
	ld (__a_2_use5), a
	ld a, (many_i8_x3)
	ld (__a_3_use5), a
	ld a, (many_i8_x4)
	ld (__a_4_use5), a
	ld a, (many_i8_x5)
	call use5
; 15     return (unsigned char)(x1 ^ x2 ^ x3 ^ x4 ^ x5);
	ld hl, many_i8_x1
	ld a, (many_i8_x2)
	xor (hl)
	ld hl, many_i8_x3
	xor (hl)
	ld hl, many_i8_x4
	xor (hl)
	ld hl, many_i8_x5
	xor (hl)
	ret
__bss:
__static_stack:
	ds 19
__end:
__s___init equ __static_stack + 19
__s_main equ __static_stack + 15
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_many_i8 equ __static_stack + 5
__a_1_many_i8 equ __s_many_i8 + 5
__a_2_many_i8 equ __s_many_i8 + 6
__a_3_many_i8 equ __s_many_i8 + 7
__a_4_many_i8 equ __s_many_i8 + 8
__a_5_many_i8 equ __s_many_i8 + 9
many_i8_x1 equ __s_many_i8 + 0
__s_op equ __static_stack + 0
__a_1_op equ __s_op + 0
many_i8_x2 equ __s_many_i8 + 1
many_i8_x3 equ __s_many_i8 + 2
many_i8_x4 equ __s_many_i8 + 3
many_i8_x5 equ __s_many_i8 + 4
__s_use5 equ __static_stack + 0
__a_1_use5 equ __s_use5 + 0
__a_2_use5 equ __s_use5 + 1
__a_3_use5 equ __s_use5 + 2
__a_4_use5 equ __s_use5 + 3
__a_5_use5 equ __s_use5 + 4
    savebin "tests\features\38\c8080.bin", __begin, __bss - __begin
