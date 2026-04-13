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
; 22 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 23     volatile int r;
; 24     r = test_two_cond_tailcall(0, 0);
	ld hl, 0
	ld (__a_1_test_two_cond_tailcall), hl
	call test_two_cond_tailcall
	ld (main_r), hl
; 25     r = test_two_cond_tailcall(1, 0);
	ld hl, 1
	ld (__a_1_test_two_cond_tailcall), hl
	ld hl, 0
	call test_two_cond_tailcall
	ld (main_r), hl
; 26     r = test_two_cond_tailcall(0, 1);
	ld hl, 0
	ld (__a_1_test_two_cond_tailcall), hl
	ld hl, 1
	call test_two_cond_tailcall
	ld (main_r), hl
; 27     r = test_simple_zero_check(0);
	ld hl, 0
	call test_simple_zero_check
	ld (main_r), hl
; 28     r = test_simple_zero_check(5);
	ld hl, 5
	call test_simple_zero_check
	ld (main_r), hl
; 29     r = test_nz_branch(0, 10);
	ld hl, 0
	ld (__a_1_test_nz_branch), hl
	ld hl, 10
	call test_nz_branch
	ld (main_r), hl
; 30     r = test_nz_branch(3, 10);
	ld hl, 3
	ld (__a_1_test_nz_branch), hl
	ld hl, 10
	call test_nz_branch
	ld (main_r), hl
; 31     return 0;
	ld hl, 0
	ret
test_two_cond_tailcall:
; 6 int test_two_cond_tailcall(int x, int y) {
	ld (__a_2_test_two_cond_tailcall), hl
; 7     if (x) return bar(x);
	ld hl, (__a_1_test_two_cond_tailcall)
	ld a, h
	or l
	jp nz, bar
; 8     if (y) return bar(x);
	ld hl, (__a_2_test_two_cond_tailcall)
	ld a, h
	or l
	jp z, l_2
	ld hl, (__a_1_test_two_cond_tailcall)
	jp bar
l_2:
; 9     return 0;
	ld hl, 0
	ret
test_simple_zero_check:
; 12 int test_simple_zero_check(int val) {
	ld (__a_1_test_simple_zero_check), hl
; 13     if (val) return 1;
	ld a, h
	or l
	jp z, l_4
	ld hl, 1
	ret
l_4:
; 14     return 0;
	ld hl, 0
	ret
test_nz_branch:
; 17 int test_nz_branch(int a, int b) {
	ld (__a_2_test_nz_branch), hl
; 18     if (a) return b;
	ld hl, (__a_1_test_nz_branch)
	ld a, h
	or l
	jp z, l_6
	ld hl, (__a_2_test_nz_branch)
	ret
l_6:
; 19     return 0;
	ld hl, 0
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
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_test_two_cond_tailcall equ __static_stack + 2
__a_1_test_two_cond_tailcall equ __s_test_two_cond_tailcall + 0
__a_2_test_two_cond_tailcall equ __s_test_two_cond_tailcall + 2
__s_test_simple_zero_check equ __static_stack + 0
__a_1_test_simple_zero_check equ __s_test_simple_zero_check + 0
__s_test_nz_branch equ __static_stack + 0
__a_1_test_nz_branch equ __s_test_nz_branch + 0
__a_2_test_nz_branch equ __s_test_nz_branch + 2
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
    savebin "tests\features\17\c8080.bin", __begin, __bss - __begin
