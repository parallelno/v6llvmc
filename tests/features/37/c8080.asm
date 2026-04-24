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
; 43 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 44     use2(a_spill_r8_reload(0x11, 0x22), k2_i8(0x33, 0x44, 0x55));
	ld a, 17
	ld (__a_1_a_spill_r8_reload), a
	ld a, 34
	call a_spill_r8_reload
	ld (__a_1_use2), a
	ld a, 51
	ld (__a_1_k2_i8), a
	ld a, 68
	ld (__a_2_k2_i8), a
	ld a, 85
	call k2_i8
	call use2
; 45     use2(multi_src_i8(0x66, 0x77, 1), 0);
	ld a, 102
	ld (__a_1_multi_src_i8), a
	ld a, 119
	ld (__a_2_multi_src_i8), a
	ld a, 1
	call multi_src_i8
	ld (__a_1_use2), a
	xor a
	call use2
; 46     mixed_widths(0xabcd, 0xef);
	ld hl, 43981
	ld (__a_1_mixed_widths), hl
	ld a, 239
	call mixed_widths
; 47     return 0;
	ld hl, 0
	ret
use2:
; 7 void use2(unsigned char a, unsigned char b) { op_acc ^= a; op_acc ^= b; }
	ld (__a_2_use2), a
	ld hl, op_acc
	ld a, (__a_1_use2)
	xor (hl)
	ld (hl), a
	ld a, (__a_2_use2)
	xor (hl)
	ld (hl), a
	ret
a_spill_r8_reload:
; 9 unsigned char a_spill_r8_reload(unsigned char x, unsigned char y) {
	ld (__a_2_a_spill_r8_reload), a
; 10     unsigned char a = op1(x);
	ld a, (__a_1_a_spill_r8_reload)
	call op1
	ld (a_spill_r8_reload_a), a
; 11     unsigned char b = op2(y);
	ld a, (__a_2_a_spill_r8_reload)
	call op2
	ld (a_spill_r8_reload_b), a
; 12     return a + b;
	ld hl, a_spill_r8_reload_a
	add (hl)
	ret
k2_i8:
; 15 unsigned char k2_i8(unsigned char x, unsigned char y, unsigned char z) {
	ld (__a_3_k2_i8), a
; 16     unsigned char a = op1(x);
	ld a, (__a_1_k2_i8)
	call op1
	ld (k2_i8_a), a
; 17     unsigned char b = op2(y);
	ld a, (__a_2_k2_i8)
	call op2
	ld (k2_i8_b), a
; 18     unsigned char s1 = (unsigned char)(a + b);
	ld hl, k2_i8_a
	add (hl)
	ld (k2_i8_s1), a
; 19     unsigned char c = op2(z);
	ld a, (__a_3_k2_i8)
	call op2
	ld (k2_i8_c), a
; 20     return (unsigned char)(s1 + a + c);
	ld hl, k2_i8_s1
	ld a, (k2_i8_a)
	add (hl)
	ld hl, k2_i8_c
	add (hl)
	ret
multi_src_i8:
; 23 unsigned char multi_src_i8(unsigned char x, unsigned char y, unsigned char c) {
	ld (__a_3_multi_src_i8), a
; 24     unsigned char a;
; 25     if (c) a = op1(x);
	or a
	jp z, l_0
	ld a, (__a_1_multi_src_i8)
	call op1
	ld (multi_src_i8_a), a
	jp l_1
l_0:
; 26     else   a = op2(x);
	ld a, (__a_1_multi_src_i8)
	call op2
	ld (multi_src_i8_a), a
l_1:
; 27     unsigned char b = op2(y);
	ld a, (__a_2_multi_src_i8)
	call op2
	ld (multi_src_i8_b), a
; 28     return a + b;
	ld hl, multi_src_i8_a
	add (hl)
	ret
mixed_widths:
; 34 void mixed_widths(unsigned int x16, unsigned char x8) {
	ld (__a_2_mixed_widths), a
; 35     unsigned int a16 = (unsigned int)op1((unsigned char)x16) + x16;
	ld a, (__a_1_mixed_widths)
	call op1
	ld e, a
	ld d, 0
	ld hl, (__a_1_mixed_widths)
	add hl, de
	ld (mixed_widths_a16), hl
; 36     unsigned char a8  = op2(x8);
	ld a, (__a_2_mixed_widths)
	call op2
	ld (mixed_widths_a8), a
; 37     unsigned int b16 = (unsigned int)op2((unsigned char)x16);
	ld a, (__a_1_mixed_widths)
	call op2
	ld l, a
	ld h, 0
	ld (mixed_widths_b16), hl
; 38     unsigned char b8  = op1(x8);
	ld a, (__a_2_mixed_widths)
	call op1
	ld (mixed_widths_b8), a
; 39     g_u16 = a16 + b16;
	ld hl, (mixed_widths_a16)
	ex hl, de
	ld hl, (mixed_widths_b16)
	add hl, de
	ld (g_u16), hl
; 40     g_u8  = (unsigned char)(a8 + b8);
	ld hl, mixed_widths_a8
	add (hl)
	ld (g_u8), a
	ret
op1:
; 5 unsigned char op1(unsigned char x) { op_acc ^= x; return (unsigned char)(x + 1); }
	ld (__a_1_op1), a
	ld hl, op_acc
	xor (hl)
	ld (hl), a
	ld a, (__a_1_op1)
	inc a
	ret
op2:
; 6 unsigned char op2(unsigned char x) { op_acc ^= x; return (unsigned char)(x + 2); }
	ld (__a_1_op2), a
	ld hl, op_acc
	xor (hl)
	ld (hl), a
	ld a, (__a_1_op2)
	add 2
	ret
__bss:
op_acc:
	ds 1
g_u16:
	ds 2
g_u8:
	ds 1
__static_stack:
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 10
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_a_spill_r8_reload equ __static_stack + 1
__a_1_a_spill_r8_reload equ __s_a_spill_r8_reload + 2
__a_2_a_spill_r8_reload equ __s_a_spill_r8_reload + 3
__s_k2_i8 equ __static_stack + 1
__a_1_k2_i8 equ __s_k2_i8 + 4
__a_2_k2_i8 equ __s_k2_i8 + 5
__a_3_k2_i8 equ __s_k2_i8 + 6
__s_use2 equ __static_stack + 8
__a_1_use2 equ __s_use2 + 0
__a_2_use2 equ __s_use2 + 1
__s_multi_src_i8 equ __static_stack + 1
__a_1_multi_src_i8 equ __s_multi_src_i8 + 2
__a_2_multi_src_i8 equ __s_multi_src_i8 + 3
__a_3_multi_src_i8 equ __s_multi_src_i8 + 4
__s_mixed_widths equ __static_stack + 1
__a_1_mixed_widths equ __s_mixed_widths + 6
__a_2_mixed_widths equ __s_mixed_widths + 8
a_spill_r8_reload_a equ __s_a_spill_r8_reload + 0
__s_op1 equ __static_stack + 0
__a_1_op1 equ __s_op1 + 0
a_spill_r8_reload_b equ __s_a_spill_r8_reload + 1
__s_op2 equ __static_stack + 0
__a_1_op2 equ __s_op2 + 0
k2_i8_a equ __s_k2_i8 + 0
k2_i8_b equ __s_k2_i8 + 1
k2_i8_s1 equ __s_k2_i8 + 2
k2_i8_c equ __s_k2_i8 + 3
multi_src_i8_a equ __s_multi_src_i8 + 0
multi_src_i8_b equ __s_multi_src_i8 + 1
mixed_widths_a16 equ __s_mixed_widths + 0
mixed_widths_a8 equ __s_mixed_widths + 2
mixed_widths_b16 equ __s_mixed_widths + 3
mixed_widths_b8 equ __s_mixed_widths + 5
    savebin "tests\features\37\c8080.bin", __begin, __bss - __begin
