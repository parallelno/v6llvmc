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
; 31     test_ult(999);
	ld hl, 999
	call test_ult
; 32     test_uge(1000);
	ld hl, 1000
	call test_uge
; 33     test_ugt(1001);
	ld hl, 1001
	call test_ugt
; 34     test_ule(1000);
	ld hl, 1000
	call test_ule
; 35     test_slt(499);
	ld hl, 499
	call test_slt
; 36     test_sge(500);
	ld hl, 500
	call test_sge
; 37     return 0;
	ld hl, 0
	ret
test_ult:
; 6 void test_ult(unsigned int x) {
	ld (__a_1_test_ult), hl
; 7     if (x < 1000) result = 1;
	ld de, 64536
	add hl, de
	ret c
	ld hl, 1
	ld (result), hl
	ret
test_uge:
; 10 void test_uge(unsigned int x) {
	ld (__a_1_test_uge), hl
; 11     if (x >= 1000) result = 2;
	ld de, 64536
	add hl, de
	ret nc
	ld hl, 2
	ld (result), hl
	ret
test_ugt:
; 14 void test_ugt(unsigned int x) {
	ld (__a_1_test_ugt), hl
; 15     if (x > 1000) result = 3;
	ld de, 64535
	add hl, de
	ret nc
	ld hl, 3
	ld (result), hl
	ret
test_ule:
; 18 void test_ule(unsigned int x) {
	ld (__a_1_test_ule), hl
; 19     if (x <= 1000) result = 4;
	ld de, 64535
	add hl, de
	ret c
	ld hl, 4
	ld (result), hl
	ret
test_slt:
; 22 void test_slt(int x) {
	ld (__a_1_test_slt), hl
; 23     if (x < 500) result = 5;
	ld de, 500
	call __o_sub_16
	ret p
	ld hl, 5
	ld (result), hl
	ret
test_sge:
; 26 void test_sge(int x) {
	ld (__a_1_test_sge), hl
; 27     if (x >= 500) result = 6;
	ld de, 500
	call __o_sub_16
	ret m
	ld hl, 6
	ld (result), hl
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
result:
	ds 2
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_test_ult equ __static_stack + 0
__a_1_test_ult equ __s_test_ult + 0
__s_test_uge equ __static_stack + 0
__a_1_test_uge equ __s_test_uge + 0
__s_test_ugt equ __static_stack + 0
__a_1_test_ugt equ __s_test_ugt + 0
__s_test_ule equ __static_stack + 0
__a_1_test_ule equ __s_test_ule + 0
__s_test_slt equ __static_stack + 0
__a_1_test_slt equ __s_test_slt + 0
__s_test_sge equ __static_stack + 0
__a_1_test_sge equ __s_test_sge + 0
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\28\c8080.bin", __begin, __bss - __begin
