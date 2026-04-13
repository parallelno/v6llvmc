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
; 33 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 34     int r = test_ne_zero(5);
	ld hl, 5
	call test_ne_zero
	ld (main_r), hl
; 35     r += test_eq_zero(0);
	ld hl, 0
	call test_eq_zero
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 36     r += test_multi_cond(1);
	ld hl, 1
	call test_multi_cond
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 37     r += test_multi_cond(2);
	ld hl, 2
	call test_multi_cond
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 38     r += test_multi_cond(3);
	ld hl, 3
	call test_multi_cond
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 39     int val = 42;
	ld hl, 42
	ld (main_val), hl
; 40     r += test_null_guard(&val);
	ld hl, main_val
	call test_null_guard
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 41     return r;
	ret
test_ne_zero:
; 7 int test_ne_zero(int x) {
	ld (__a_1_test_ne_zero), hl
; 8     if (x)
	ld a, h
	or l
	jp nz, bar
; 9         return bar(x);
; 10     return 0;
	ld hl, 0
	ret
test_eq_zero:
; 13 int test_eq_zero(int x) {
	ld (__a_1_test_eq_zero), hl
; 14     if (!x)
	ld a, h
	or l
	jp nz, l_2
; 15         return 0;
	ld hl, 0
	ret
l_2:
; 16     return bar(x);
	jp bar
test_multi_cond:
; 19 int test_multi_cond(int x) {
	ld (__a_1_test_multi_cond), hl
; 20     if (x == 1)
	ld de, 1
	call __o_xor_16
	jp nz, l_4
; 21         return 10;
	ld hl, 10
	ret
l_4:
; 22     if (x == 2)
	ld hl, (__a_1_test_multi_cond)
	ld de, 2
	call __o_xor_16
	jp nz, l_6
; 23         return 20;
	ld hl, 20
	ret
l_6:
; 24     return bar(x);
	ld hl, (__a_1_test_multi_cond)
	jp bar
test_null_guard:
; 27 int test_null_guard(int *p) {
	ld (__a_1_test_null_guard), hl
; 28     if (p)
	ld a, h
	or l
	jp z, l_8
; 29         return *p;
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ret
l_8:
; 30     return -1;
	ld hl, 65535
	ret
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
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 4
__a_2_main equ __s_main + 6
main_r equ __s_main + 0
__s_test_ne_zero equ __static_stack + 2
__a_1_test_ne_zero equ __s_test_ne_zero + 0
__s_test_eq_zero equ __static_stack + 2
__a_1_test_eq_zero equ __s_test_eq_zero + 0
__s_test_multi_cond equ __static_stack + 2
__a_1_test_multi_cond equ __s_test_multi_cond + 0
main_val equ __s_main + 2
__s_test_null_guard equ __static_stack + 0
__a_1_test_null_guard equ __s_test_null_guard + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\10\c8080.bin", __begin, __bss - __begin
