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
; 24     r = test_cond_zero_tailcall(0);
	ld hl, 0
	call test_cond_zero_tailcall
	ld (main_r), hl
; 25     r = test_cond_zero_tailcall(5);
	ld hl, 5
	call test_cond_zero_tailcall
	ld (main_r), hl
; 26     r = test_cond_zero_return_zero(0);
	ld hl, 0
	call test_cond_zero_return_zero
	ld (main_r), hl
; 27     r = test_cond_zero_return_zero(5);
	ld hl, 5
	call test_cond_zero_return_zero
	ld (main_r), hl
; 28     r = test_nonzero_path(0);
	ld hl, 0
	call test_nonzero_path
	ld (main_r), hl
; 29     r = test_nonzero_path(5);
	ld hl, 5
	call test_nonzero_path
	ld (main_r), hl
; 30     return 0;
	ld hl, 0
	ret
test_cond_zero_tailcall:
; 7 int test_cond_zero_tailcall(int x) {
	ld (__a_1_test_cond_zero_tailcall), hl
; 8     if (x == 0) return bar(0);
	ld a, h
	or l
	ret nz
	ld hl, 0
	jp bar
test_cond_zero_return_zero:
; 12 int test_cond_zero_return_zero(int x) {
	ld (__a_1_test_cond_zero_return_zero), hl
; 13     if (x == 0) return bar(0);
	ld a, h
	or l
	jp nz, l_2
	ld hl, 0
	jp bar
l_2:
; 14     return 0;
	ld hl, 0
	ret
test_nonzero_path:
; 17 int test_nonzero_path(int x) {
	ld (__a_1_test_nonzero_path), hl
; 18     if (x != 0) return x;
	ld a, h
	or l
	ret nz
; 19     return bar(0);
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
__s_test_cond_zero_tailcall equ __static_stack + 2
__a_1_test_cond_zero_tailcall equ __s_test_cond_zero_tailcall + 0
__s_test_cond_zero_return_zero equ __static_stack + 2
__a_1_test_cond_zero_return_zero equ __s_test_cond_zero_return_zero + 0
__s_test_nonzero_path equ __static_stack + 2
__a_1_test_nonzero_path equ __s_test_nonzero_path + 0
__s_bar equ __static_stack + 0
__a_1_bar equ __s_bar + 0
    savebin "tests\features\15\c8080.bin", __begin, __bss - __begin
