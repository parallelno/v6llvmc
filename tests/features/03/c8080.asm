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
; 39 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 40     countdown(5);
	ld a, 5
	call countdown
; 41     countup(250);
	ld a, 250
	call countup
; 42     xor_test(5, 5);
	ld hl, 5
	ld (__a_1_xor_test), hl
	call xor_test
; 43     sub_test(10, 10);
	ld hl, 10
	ld (__a_1_sub_test), hl
	call sub_test
; 44     return 0;
	ld hl, 0
	ret
countdown:
; 7 void countdown(unsigned char n) {
	ld (__a_1_countdown), a
; 8     while (n != 0) {
l_0:
	or a
	ret z
; 9         g_port = n;
	ld (g_port), a
; 10         n--;
	ld a, (__a_1_countdown)
	dec a
	ld (__a_1_countdown), a
	jp l_0
countup:
; 14 void countup(unsigned char start) {
	ld (__a_1_countup), a
; 15     unsigned char i;
; 16     i = start;
	ld (countup_i), a
; 17     while (i != 0) {
l_2:
	or a
	ret z
; 18         g_port = i;
	ld (g_port), a
; 19         i++;
	ld a, (countup_i)
	inc a
	ld (countup_i), a
	jp l_2
xor_test:
; 23 int xor_test(int a, int b) {
	ld (__a_2_xor_test), hl
; 24     int r;
; 25     r = a ^ b;
	ld hl, (__a_1_xor_test)
	ex hl, de
	ld hl, (__a_2_xor_test)
	call __o_xor_16
	ld (xor_test_r), hl
; 26     if (r == 0)
	ld a, h
	or l
	jp nz, l_4
; 27         return 1;
	ld hl, 1
	ret
l_4:
; 28     return 0;
	ld hl, 0
	ret
sub_test:
; 31 int sub_test(int a, int b) {
	ld (__a_2_sub_test), hl
; 32     int r;
; 33     r = a - b;
	ex hl, de
	ld hl, (__a_1_sub_test)
	call __o_sub_16
	ld (sub_test_r), hl
; 34     if (r == 0)
	ld a, h
	or l
	jp nz, l_6
; 35         return 1;
	ld hl, 1
	ret
l_6:
; 36     return 0;
	ld hl, 0
	ret
__o_xor_16:
; 310 void __o_xor_16() {
; 311     asm {

        ld   a, h
        xor  d
        ld   h, a
        ld   a, l
        xor  e
        ld   l, a
        or   h         ; Flag Z used for compare

	ret
__o_sub_16:
; 265 void __o_sub_16() {
; 266     asm {

        ld   a, l
        sub  e
        ld   l, a
        ld   a, h
        sbc  d
        ld   h, a

	ret
__bss:
g_port:
	ds 1
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_countdown equ __static_stack + 0
__a_1_countdown equ __s_countdown + 0
__s_countup equ __static_stack + 0
__a_1_countup equ __s_countup + 1
__s_xor_test equ __static_stack + 0
__a_1_xor_test equ __s_xor_test + 2
__a_2_xor_test equ __s_xor_test + 4
__s_sub_test equ __static_stack + 0
__a_1_sub_test equ __s_sub_test + 2
__a_2_sub_test equ __s_sub_test + 4
countup_i equ __s_countup + 0
xor_test_r equ __s_xor_test + 0
sub_test_r equ __s_sub_test + 0
__s___o_xor_16 equ __static_stack + 0
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\03\c8080.bin", __begin, __bss - __begin
