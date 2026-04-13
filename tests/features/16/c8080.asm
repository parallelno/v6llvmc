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
; 21 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 22     volatile int r;
; 23     r = test_cond_zero_return_zero(0);
	ld hl, 0
	call test_cond_zero_return_zero
	ld (main_r), hl
; 24     r = test_cond_zero_return_zero(5);
	ld hl, 5
	call test_cond_zero_return_zero
	ld (main_r), hl
; 25     r = test_both_call_zero(0);
	ld hl, 0
	call test_both_call_zero
	ld (main_r), hl
; 26     r = test_both_call_zero(5);
	ld hl, 5
	call test_both_call_zero
	ld (main_r), hl
; 27     r = test_one_path_zero(0);
	ld hl, 0
	call test_one_path_zero
	ld (main_r), hl
; 28     r = test_one_path_zero(5);
	ld hl, 5
	call test_one_path_zero
	ld (main_r), hl
; 29     return 0;
	ld hl, 0
	ret
test_cond_zero_return_zero:
; 6 int test_cond_zero_return_zero(int x) {
	ld (__a_1_test_cond_zero_return_zero), hl
; 7     if (x == 0) return bar(0);
	ld a, h
	or l
	jp nz, l_0
	ld hl, 0
	jp bar
l_0:
; 8     return 0;
	ld hl, 0
	ret
test_both_call_zero:
; 11 int test_both_call_zero(int x) {
	ld (__a_1_test_both_call_zero), hl
; 12     if (x == 0) return bar(0);
	ld a, h
	or l
	jp nz, l_2
	ld hl, 0
	jp bar
l_2:
; 13     return bar(0);
	ld hl, 0
	jp bar
test_one_path_zero:
; 16 int test_one_path_zero(int x) {
	ld (__a_1_test_one_path_zero), hl
; 17     if (x == 0) return bar(0);
	ld a, h
	or l
	ret nz
	ld hl, 0
bar:
; 4 int bar(int x) { return x + 1; }
	ld (__a_1_bar), hl
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
__s_test_cond_zero_return_zero equ __static_stack + 2
__a_1_test_cond_zero_return_zero equ __s_test_cond_zero_return_zero + 0
__s_test_both_call_zero equ __static_stack + 2
__a_1_test_both_call_zero equ __s_test_both_call_zero + 0
__s_test_one_path_zero equ __static_stack + 2
__a_1_test_one_path_zero equ __s_test_one_path_zero + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
    savebin "tests\features\16\c8080.bin", __begin, __bss - __begin
