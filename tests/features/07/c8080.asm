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
; 25 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 26     int r = test_pattern_a(1);
	ld hl, 1
	call test_pattern_a
	ld (main_r), hl
; 27     r += test_pattern_b(0);
	ld hl, 0
	call test_pattern_b
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 28     r += test_pattern_c(1);
	ld hl, 1
	call test_pattern_c
	ex hl, de
	ld hl, (main_r)
	add hl, de
	ld (main_r), hl
; 29     return r;
	ret
test_pattern_a:
; 7 int test_pattern_a(int x) {
	ld (__a_1_test_pattern_a), hl
; 8     if (x)
	ld a, h
	or l
	jp nz, bar
; 9         return bar(x);
; 10     return 0;
	ld hl, 0
	ret
test_pattern_b:
; 13 int test_pattern_b(int x) {
	ld (__a_1_test_pattern_b), hl
; 14     if (x)
	ld a, h
	or l
	jp z, l_2
; 15         return 0;
	ld hl, 0
	ret
l_2:
; 16     return bar(x);
	jp bar
test_pattern_c:
; 19 int test_pattern_c(int x) {
	ld (__a_1_test_pattern_c), hl
; 20     if (x)
	ld a, h
	or l
	jp nz, bar
; 21         return bar(x);
; 22     return baz(x);
	jp baz
bar:
; 4 int bar(int x) { return x + 1; }
	ld (__a_1_bar), hl
	inc hl
	ret
baz:
; 5 int baz(int x) { return x + 2; }
	ld (__a_1_baz), hl
	inc hl
	inc hl
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
__s_test_pattern_a equ __static_stack + 2
__a_1_test_pattern_a equ __s_test_pattern_a + 0
__s_test_pattern_b equ __static_stack + 2
__a_1_test_pattern_b equ __s_test_pattern_b + 0
__s_test_pattern_c equ __static_stack + 2
__a_1_test_pattern_c equ __s_test_pattern_c + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
__s_baz equ __static_stack + 0
__a_1_baz equ __s_baz + 0
    savebin "tests\features\07\c8080.bin", __begin, __bss - __begin
