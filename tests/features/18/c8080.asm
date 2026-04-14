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
; 43 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 44     volatile int r;
; 45     r = test_ne_same_bytes(0);
	ld hl, 0
	call test_ne_same_bytes
	ld (main_r), hl
; 46     r = test_ne_same_bytes(0x4242);
	ld hl, 16962
	call test_ne_same_bytes
	ld (main_r), hl
; 47     r = test_ne_same_bytes(0x1234);
	ld hl, 4660
	call test_ne_same_bytes
	ld (main_r), hl
; 48     r = test_eq_same_bytes(0);
	ld hl, 0
	call test_eq_same_bytes
	ld (main_r), hl
; 49     r = test_eq_same_bytes(0x4242);
	ld hl, 16962
	call test_eq_same_bytes
	ld (main_r), hl
; 50     r = test_ne_diff_bytes(0);
	ld hl, 0
	call test_ne_diff_bytes
	ld (main_r), hl
; 51     r = test_ne_diff_bytes(0x1234);
	ld hl, 4660
	call test_ne_diff_bytes
	ld (main_r), hl
; 52     r = test_ne_0101(0);
	ld hl, 0
	call test_ne_0101
	ld (main_r), hl
; 53     r = test_ne_0101(0x0101);
	ld hl, 257
	call test_ne_0101
	ld (main_r), hl
; 54     return 0;
	ld hl, 0
	ret
test_ne_same_bytes:
; 8 int test_ne_same_bytes(int x) {
	ld (__a_1_test_ne_same_bytes), hl
; 9     if (x != 0x4242) {
	ld de, 16962
	call __o_xor_16
	call nz, action_a
; 10         action_a();
; 11     }
; 12     action_b();
	call action_b
; 13     return x;
	ld hl, (__a_1_test_ne_same_bytes)
	ret
test_eq_same_bytes:
; 17 int test_eq_same_bytes(int x) {
	ld (__a_1_test_eq_same_bytes), hl
; 18     if (x == 0x4242) {
	ld de, 16962
	call __o_xor_16
	call z, action_a
; 19         action_a();
; 20     }
; 21     action_b();
	call action_b
; 22     return x;
	ld hl, (__a_1_test_eq_same_bytes)
	ret
test_ne_diff_bytes:
; 26 int test_ne_diff_bytes(int x) {
	ld (__a_1_test_ne_diff_bytes), hl
; 27     if (x != 0x1234) {
	ld de, 4660
	call __o_xor_16
	call nz, action_a
; 28         action_a();
; 29     }
; 30     action_b();
	call action_b
; 31     return x;
	ld hl, (__a_1_test_ne_diff_bytes)
	ret
test_ne_0101:
; 35 int test_ne_0101(int x) {
	ld (__a_1_test_ne_0101), hl
; 36     if (x != 0x0101) {
	ld de, 257
	call __o_xor_16
	call nz, action_a
; 37         action_a();
; 38     }
; 39     action_b();
	call action_b
; 40     return x;
	ld hl, (__a_1_test_ne_0101)
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
action_a:
; 4 int action_a(void) { return 1; }
	ld hl, 1
	ret
action_b:
; 5 int action_b(void) { return 2; }
	ld hl, 2
	ret
__bss:
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_test_ne_same_bytes equ __static_stack + 0
__a_1_test_ne_same_bytes equ __s_test_ne_same_bytes + 0
__s_test_eq_same_bytes equ __static_stack + 0
__a_1_test_eq_same_bytes equ __s_test_eq_same_bytes + 0
__s_test_ne_diff_bytes equ __static_stack + 0
__a_1_test_ne_diff_bytes equ __s_test_ne_diff_bytes + 0
__s_test_ne_0101 equ __static_stack + 0
__a_1_test_ne_0101 equ __s_test_ne_0101 + 0
__s___o_xor_16 equ __static_stack + 0
__s_action_a equ __static_stack + 0
__s_action_b equ __static_stack + 0
    savebin "tests\features\18\c8080.bin", __begin, __bss - __begin
