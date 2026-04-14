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
; 22     int r = nested_add(5);
	ld hl, 5
	call nested_add
	ld (main_r), hl
; 23     return r;
	ret
nested_add:
; 13 int nested_add(int n) {
	ld (__a_1_nested_add), hl
; 14     int a = get_val();
	call get_val
	ld (nested_add_a), hl
; 15     int b = get_val();
	call get_val
	ld (nested_add_b), hl
; 16     int c = a + b + n;
	ld hl, (nested_add_a)
	ex hl, de
	ld hl, (nested_add_b)
	add hl, de
	ex hl, de
	ld hl, (__a_1_nested_add)
	add hl, de
	ld (nested_add_c), hl
; 17     use_val(c);
	call use_val
; 18     return a + b;
	ld hl, (nested_add_a)
	ex hl, de
	ld hl, (nested_add_b)
	add hl, de
	ret
get_val:
; 9 int get_val(void) {
; 10     return sink_val;
	ld hl, (sink_val)
	ret
use_val:
; 5 void use_val(int x) {
	ld (__a_1_use_val), hl
; 6     sink_val = x;
	ld (sink_val), hl
	ret
__bss:
sink_val:
	ds 2
__static_stack:
	ds 16
__end:
__s___init equ __static_stack + 16
__s_main equ __static_stack + 10
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r equ __s_main + 0
__s_nested_add equ __static_stack + 2
__a_1_nested_add equ __s_nested_add + 6
nested_add_a equ __s_nested_add + 0
nested_add_b equ __s_nested_add + 2
nested_add_c equ __s_nested_add + 4
__s_use_val equ __static_stack + 0
__a_1_use_val equ __s_use_val + 0
__s_get_val equ __static_stack + 0
    savebin "tests\features\22\c8080.bin", __begin, __bss - __begin
