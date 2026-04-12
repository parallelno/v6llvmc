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
; 35 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 36     test_multi_zext(5, 10);
	ld a, 5
	ld (__a_1_test_multi_zext), a
	ld a, 10
	call test_multi_zext
; 37     test_same_imm();
	call test_same_imm
; 38     test_sequential_values();
	call test_sequential_values
; 39     test_mov_propagation(7);
	ld a, 7
	call test_mov_propagation
; 40     return 0;
	ld hl, 0
	ret
test_multi_zext:
; 12 void test_multi_zext(unsigned char a, unsigned char b) {
	ld (__a_2_test_multi_zext), a
; 13     unsigned int wide_a = a;
	ld hl, (__a_1_test_multi_zext)
	ld h, 0
	ld (test_multi_zext_wide_a), hl
; 14     unsigned int wide_b = b;
	ld hl, (__a_2_test_multi_zext)
	ld h, 0
	ld (test_multi_zext_wide_b), hl
; 15     use16(wide_a + wide_b);
	ld hl, (test_multi_zext_wide_a)
	ex hl, de
	ld hl, (test_multi_zext_wide_b)
	add hl, de
	jp use16
test_same_imm:
; 18 void test_same_imm(void) {
; 19     use8(42);
	ld a, 42
	call use8
; 20     use8(42);
	ld a, 42
	jp use8
test_sequential_values:
; 23 void test_sequential_values(void) {
; 24     use8(10);
	ld a, 10
	call use8
; 25     use8(11);
	ld a, 11
	jp use8
test_mov_propagation:
; 28 void test_mov_propagation(unsigned char a) {
	ld (__a_1_test_mov_propagation), a
; 29     unsigned int w1 = a;
	ld hl, (__a_1_test_mov_propagation)
	ld h, 0
	ld (test_mov_propagation_w1), hl
; 30     use16(w1);
	call use16
; 31     unsigned int w2 = a;
	ld hl, (__a_1_test_mov_propagation)
	ld h, 0
	ld (test_mov_propagation_w2), hl
; 32     use16(w2);
use16:
; 9 void use16(unsigned int val) { sink16 = val; }
	ld (__a_1_use16), hl
	ld (sink16), hl
	ret
use8:
; 8 void use8(unsigned char val) { sink8 = val; }
	ld (__a_1_use8), a
	ld (sink8), a
	ret
__bss:
sink8:
	ds 1
sink16:
	ds 2
__static_stack:
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_test_multi_zext equ __static_stack + 2
__a_1_test_multi_zext equ __s_test_multi_zext + 4
__a_2_test_multi_zext equ __s_test_multi_zext + 5
__s_test_mov_propagation equ __static_stack + 2
__a_1_test_mov_propagation equ __s_test_mov_propagation + 4
test_multi_zext_wide_a equ __s_test_multi_zext + 0
test_multi_zext_wide_b equ __s_test_multi_zext + 2
__s_use16 equ __static_stack + 0
__a_1_use16 equ __s_use16 + 0
__s_test_same_imm equ __static_stack + 1
__s_use8 equ __static_stack + 0
__a_1_use8 equ __s_use8 + 0
__s_test_sequential_values equ __static_stack + 1
test_mov_propagation_w1 equ __s_test_mov_propagation + 0
test_mov_propagation_w2 equ __s_test_mov_propagation + 2
    savebin "tests\features\05\c8080.bin", __begin, __bss - __begin
