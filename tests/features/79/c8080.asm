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
; 14 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 15     byte_sink = 0x5a;
	ld a, 90
	ld (byte_sink), a
; 16     middle(3);
	ld hl, 3
	call middle
; 17     return 0;
	ld hl, 0
	ret
middle:
; 9 void middle(unsigned int value) {
	ld (__a_1_middle), hl
; 10     leaf(value + 2);
	inc hl
	inc hl
	call leaf
; 11     byte_sink = (unsigned char)value;
	ld a, (__a_1_middle)
	ld (byte_sink), a
	ret
leaf:
; 4 void leaf(unsigned int value) {
	ld (__a_1_leaf), hl
; 5     unsigned int local = value + 1;
	inc hl
	ld (leaf_local), hl
; 6     word_sink = local;
	ld (word_sink), hl
	ret
__bss:
byte_sink:
	ds 1
word_sink:
	ds 2
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_middle equ __static_stack + 4
__a_1_middle equ __s_middle + 0
__s_leaf equ __static_stack + 0
__a_1_leaf equ __s_leaf + 2
leaf_local equ __s_leaf + 0
    savebin ".\tests\features\79\c8080.bin", __begin, __bss - __begin
