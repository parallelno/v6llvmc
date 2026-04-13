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
; 30 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 31     int r = test_ne_zero(5);
	ld hl, 5
	call test_ne_zero
	ld (main_r), hl
; 32     r += test_eq_zero(0);
	ld hl, 0
	call test_eq_zero
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 33     r += test_const_42(42);
	ld hl, 42
	call test_const_42
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 34     r += test_different_const(1);
	ld hl, 1
	call test_different_const
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 35     return r;
	ret
test_ne_zero:
; 6 int test_ne_zero(int x) {
	ld (__a_1_test_ne_zero), hl
; 7     if (x)
	ld a, h
	or l
	jp nz, bar
; 8         return bar(x);
; 9     return 0;
	ld hl, 0
	ret
test_eq_zero:
; 12 int test_eq_zero(int x) {
	ld (__a_1_test_eq_zero), hl
; 13     if (!x)
	ld a, h
	or l
	jp nz, l_2
; 14         return 0;
	ld hl, 0
	ret
l_2:
; 15     return bar(x);
	jp bar
test_const_42:
; 18 int test_const_42(int x) {
	ld (__a_1_test_const_42), hl
; 19     if (x == 42)
	ld de, 42
	call __o_xor_16
	jp nz, l_4
; 20         return 42;
	ld hl, 42
	ret
l_4:
; 21     return bar(x);
	ld hl, (__a_1_test_const_42)
	jp bar
test_different_const:
; 24 int test_different_const(int x) {
	ld (__a_1_test_different_const), hl
; 25     if (x == 1)
	ld de, 1
	call __o_xor_16
	jp nz, l_6
; 26         return 0;
	ld hl, 0
	ret
l_6:
; 27     return bar(x);
	ld hl, (__a_1_test_different_const)
bar:
; 4 int bar(int x) { return x + 1; }
	ld (__a_1_bar), hl
	inc hl
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
__bss:
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_test_ne_zero equ __static_stack + 2
__a_1_test_ne_zero equ __s_test_ne_zero + 0
__s_test_eq_zero equ __static_stack + 2
__a_1_test_eq_zero equ __s_test_eq_zero + 0
__s_test_const_42 equ __static_stack + 2
__a_1_test_const_42 equ __s_test_const_42 + 0
__s_test_different_const equ __static_stack + 2
__a_1_test_different_const equ __s_test_different_const + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\09\c8080.bin", __begin, __bss - __begin
