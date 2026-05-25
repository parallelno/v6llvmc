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
; 28 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 29     acc_int = 0x1234;
	ld hl, 4660
	ld (acc_int), hl
; 30     test_dead_hi();
	call test_dead_hi
; 31     test_chain_and_dead_hi();
	call test_chain_and_dead_hi
; 32     return 0;
	ld hl, 0
	ret
test_dead_hi:
; 18 void test_dead_hi(void) {
; 19     int r = get_val();
	call get_val
	ld (test_dead_hi_r), hl
; 20     use_byte((char)(r >> 8));
	ld a, h
	jp use_byte
test_chain_and_dead_hi:
; 23 void test_chain_and_dead_hi(void) {
; 24     int r = get_val();
	call get_val
	ld (test_chain_and_dead_hi_r), hl
; 25     draw_stub((char)r, (char)(r >> 8));
	ld a, (test_chain_and_dead_hi_r)
	ld (__a_1_draw_stub), a
	ld a, h
	jp draw_stub
get_val:
; 14 int get_val(void) { return acc_int; }
	ld hl, (acc_int)
	ret
use_byte:
; 15 void use_byte(char b)              { acc_char ^= b; }
	ld (__a_1_use_byte), a
	ld hl, acc_char
	xor (hl)
	ld (hl), a
	ret
draw_stub:
; 16 void draw_stub(char x1, char y1)   { acc_char ^= x1; acc_char ^= y1; }
	ld (__a_2_draw_stub), a
	ld hl, acc_char
	ld a, (__a_1_draw_stub)
	xor (hl)
	ld (hl), a
	ld a, (__a_2_draw_stub)
	xor (hl)
	ld (hl), a
	ret
__bss:
acc_int:
	ds 2
acc_char:
	ds 1
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_test_dead_hi equ __static_stack + 1
test_dead_hi_r equ __s_test_dead_hi + 0
__s_use_byte equ __static_stack + 0
__a_1_use_byte equ __s_use_byte + 0
__s_test_chain_and_dead_hi equ __static_stack + 2
test_chain_and_dead_hi_r equ __s_test_chain_and_dead_hi + 0
__s_draw_stub equ __static_stack + 0
__a_1_draw_stub equ __s_draw_stub + 0
__a_2_draw_stub equ __s_draw_stub + 1
__s_get_val equ __static_stack + 0
    savebin "tests\features\63\c8080.bin", __begin, __bss - __begin
