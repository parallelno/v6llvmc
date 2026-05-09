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
; 34 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 35     use2(shape_a(0x11),            shape_a(0));
	ld a, 17
	call shape_a
	ld (__a_1_use2), a
	xor a
	call shape_a
	call use2
; 36     use2(shape_a_dead(0x22, 0x33), shape_a_dead(0x44, 0));
	ld a, 34
	ld (__a_1_shape_a_dead), a
	ld a, 51
	call shape_a_dead
	ld (__a_1_use2), a
	ld a, 68
	ld (__a_1_shape_a_dead), a
	xor a
	call shape_a_dead
	call use2
; 37     use2(shape_a_live(0x55, 1),    shape_a_live(0x66, 0));
	ld a, 85
	ld (__a_1_shape_a_live), a
	ld a, 1
	call shape_a_live
	ld (__a_1_use2), a
	ld a, 102
	ld (__a_1_shape_a_live), a
	xor a
	call shape_a_live
	call use2
; 38     sink(shape_a_live_loop(0x77, 5));
	ld a, 119
	ld (__a_1_shape_a_live_loop), a
	ld a, 5
	call shape_a_live_loop
	call sink
; 39     return 0;
	ld hl, 0
	ret
use2:
; 7 void          use2(unsigned char a, unsigned char b) { op_acc ^= a; op_acc ^= b; }
	ld (__a_2_use2), a
	ld hl, op_acc
	ld a, (__a_1_use2)
	xor (hl)
	ld (hl), a
	ld a, (__a_2_use2)
	xor (hl)
	ld (hl), a
	ret
shape_a:
; 9 unsigned char shape_a(unsigned char a) {
	ld (__a_1_shape_a), a
; 10     if (a) return 1;
	or a
	jp z, l_0
	ld a, 1
	ret
l_0:
; 11     return 0;
	xor a
	ret
shape_a_dead:
; 14 unsigned char shape_a_dead(unsigned char x, unsigned char y) {
	ld (__a_2_shape_a_dead), a
; 15     if (y) return x;
	or a
	jp z, l_2
	ld a, (__a_1_shape_a_dead)
	ret
l_2:
; 16     return 0;
	xor a
	ret
shape_a_live:
; 19 unsigned char shape_a_live(unsigned char val_in_A, unsigned char cond) {
	ld (__a_2_shape_a_live), a
; 20     unsigned char r = op1(val_in_A);
	ld a, (__a_1_shape_a_live)
	call op1
	ld (shape_a_live_r), a
; 21     if (cond) return (unsigned char)(r + 1);
	ld a, (__a_2_shape_a_live)
	or a
	jp z, l_4
	ld a, (shape_a_live_r)
	inc a
	ret
l_4:
; 22     return r;
	ld a, (shape_a_live_r)
	ret
sink:
; 6 void          sink(unsigned char x) { op_acc ^= x; }
	ld (__a_1_sink), a
	ld hl, op_acc
	xor (hl)
	ld (hl), a
	ret
shape_a_live_loop:
; 25 unsigned char shape_a_live_loop(unsigned char seed, unsigned char n) {
	ld (__a_2_shape_a_live_loop), a
; 26     unsigned char acc = seed;
	ld a, (__a_1_shape_a_live_loop)
	ld (shape_a_live_loop_acc), a
; 27     while (n) {
l_6:
	ld a, (__a_2_shape_a_live_loop)
	or a
	jp z, l_7
; 28         acc = op1(acc);
	ld a, (shape_a_live_loop_acc)
	call op1
	ld (shape_a_live_loop_acc), a
; 29         n--;
	ld a, (__a_2_shape_a_live_loop)
	dec a
	ld (__a_2_shape_a_live_loop), a
	jp l_6
l_7:
; 30     }
; 31     return acc;
	ld a, (shape_a_live_loop_acc)
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
__bss:
op_acc:
	ds 1
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_shape_a equ __static_stack + 0
__a_1_shape_a equ __s_shape_a + 0
__s_use2 equ __static_stack + 4
__a_1_use2 equ __s_use2 + 0
__a_2_use2 equ __s_use2 + 1
__s_shape_a_dead equ __static_stack + 0
__a_1_shape_a_dead equ __s_shape_a_dead + 0
__a_2_shape_a_dead equ __s_shape_a_dead + 1
__s_shape_a_live equ __static_stack + 1
__a_1_shape_a_live equ __s_shape_a_live + 1
__a_2_shape_a_live equ __s_shape_a_live + 2
__s_shape_a_live_loop equ __static_stack + 1
__a_1_shape_a_live_loop equ __s_shape_a_live_loop + 1
__a_2_shape_a_live_loop equ __s_shape_a_live_loop + 2
__s_sink equ __static_stack + 4
__a_1_sink equ __s_sink + 0
shape_a_live_r equ __s_shape_a_live + 0
__s_op1 equ __static_stack + 0
__a_1_op1 equ __s_op1 + 0
shape_a_live_loop_acc equ __s_shape_a_live_loop + 0
    savebin "tests\features\62\c8080.bin", __begin, __bss - __begin
