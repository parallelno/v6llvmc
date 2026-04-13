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
; 35     int r = test_ne_zero(5);
	ld hl, 5
	call test_ne_zero
	ld (main_r), hl
; 36     r += test_eq_zero(0);
	ld hl, 0
	call test_eq_zero
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 37     r += test_while_loop(10);
	ld hl, 10
	call test_while_loop
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 38     int val = 42;
	ld hl, 42
	ld (main_val), hl
; 39     r += test_null_ptr(&val);
	ld hl, main_val
	call test_null_ptr
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 40     return r;
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
test_while_loop:
; 19 int test_while_loop(int n) {
	ld (__a_1_test_while_loop), hl
; 20     volatile int sum = 0;
	ld hl, 0
	ld (test_while_loop_sum), hl
; 21     while (n) {
l_4:
	ld hl, (__a_1_test_while_loop)
	ld a, h
	or l
	jp z, l_5
; 22         sum += n;
	ld hl, (test_while_loop_sum)
	ex hl, de
	ld hl, (__a_1_test_while_loop)
	add hl, de
	ld (test_while_loop_sum), hl
; 23         n--;
	ld hl, (__a_1_test_while_loop)
	dec hl
	ld (__a_1_test_while_loop), hl
	jp l_4
l_5:
; 24     }
; 25     return sum;
	ld hl, (test_while_loop_sum)
	ret
test_null_ptr:
; 28 int test_null_ptr(int *p) {
	ld (__a_1_test_null_ptr), hl
; 29     if (p)
	ld a, h
	or l
	jp z, l_6
; 30         return *p;
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ret
l_6:
; 31     return -1;
	ld hl, 65535
	ret
bar:
; 4 int bar(int x) { return x + 1; }
	ld (__a_1_bar), hl
	inc hl
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
__s_test_while_loop equ __static_stack + 0
__a_1_test_while_loop equ __s_test_while_loop + 2
main_val equ __s_main + 2
__s_test_null_ptr equ __static_stack + 0
__a_1_test_null_ptr equ __s_test_null_ptr + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
test_while_loop_sum equ __s_test_while_loop + 0
    savebin "tests\features\08\c8080.bin", __begin, __bss - __begin
