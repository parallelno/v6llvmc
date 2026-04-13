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
; 20 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 21     volatile int r;
; 22     r = select_second(1, 10, 20);
	ld hl, 1
	ld (__a_1_select_second), hl
	ld hl, 10
	ld (__a_2_select_second), hl
	ld hl, 20
	call select_second
	ld (main_r), hl
; 23     r = select_second(0, 10, 20);
	ld hl, 0
	ld (__a_1_select_second), hl
	ld hl, 10
	ld (__a_2_select_second), hl
	ld hl, 20
	call select_second
	ld (main_r), hl
; 24     r = select_on_zero(0, 100, 200);
	ld hl, 0
	ld (__a_1_select_on_zero), hl
	ld hl, 100
	ld (__a_2_select_on_zero), hl
	ld hl, 200
	call select_on_zero
	ld (main_r), hl
; 25     r = select_on_zero(5, 100, 200);
	ld hl, 5
	ld (__a_1_select_on_zero), hl
	ld hl, 100
	ld (__a_2_select_on_zero), hl
	ld hl, 200
	call select_on_zero
	ld (main_r), hl
; 26     r = select_nonzero(0, 100, 200);
	ld hl, 0
	ld (__a_1_select_nonzero), hl
	ld hl, 100
	ld (__a_2_select_nonzero), hl
	ld hl, 200
	call select_nonzero
	ld (main_r), hl
; 27     r = select_nonzero(5, 100, 200);
	ld hl, 5
	ld (__a_1_select_nonzero), hl
	ld hl, 100
	ld (__a_2_select_nonzero), hl
	ld hl, 200
	call select_nonzero
	ld (main_r), hl
; 28     return 0;
	ld hl, 0
	ret
select_second:
; 5 int select_second(int a, int b, int c) {
	ld (__a_3_select_second), hl
; 6     if (a) return b;
	ld hl, (__a_1_select_second)
	ld a, h
	or l
	jp z, l_0
	ld hl, (__a_2_select_second)
	ret
l_0:
; 7     return c;
	ld hl, (__a_3_select_second)
	ret
select_on_zero:
; 10 int select_on_zero(int x, int a, int b) {
	ld (__a_3_select_on_zero), hl
; 11     if (x == 0) return a;
	ld hl, (__a_1_select_on_zero)
	ld a, h
	or l
	jp nz, l_2
	ld hl, (__a_2_select_on_zero)
	ret
l_2:
; 12     return b;
	ld hl, (__a_3_select_on_zero)
	ret
select_nonzero:
; 15 int select_nonzero(int x, int a, int b) {
	ld (__a_3_select_nonzero), hl
; 16     if (x != 0) return a;
	ld hl, (__a_1_select_nonzero)
	ld a, h
	or l
	jp z, l_4
	ld hl, (__a_2_select_nonzero)
	ret
l_4:
; 17     return b;
	ld hl, (__a_3_select_nonzero)
	ret
__bss:
__static_stack:
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_select_second equ __static_stack + 0
__a_1_select_second equ __s_select_second + 0
__a_2_select_second equ __s_select_second + 2
__a_3_select_second equ __s_select_second + 4
__s_select_on_zero equ __static_stack + 0
__a_1_select_on_zero equ __s_select_on_zero + 0
__a_2_select_on_zero equ __s_select_on_zero + 2
__a_3_select_on_zero equ __s_select_on_zero + 4
__s_select_nonzero equ __static_stack + 0
__a_1_select_nonzero equ __s_select_nonzero + 0
__a_2_select_nonzero equ __s_select_nonzero + 2
__a_3_select_nonzero equ __s_select_nonzero + 4
    savebin "tests\features\12\c8080.bin", __begin, __bss - __begin
