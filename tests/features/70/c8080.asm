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
; 23 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 24     volatile s8  r1 = lookup_zext(42);
	ld a, 42
	call lookup_zext
	ld (main_r1), a
; 25     volatile u16 r2 = zext_add(10, 100);
	ld a, 10
	ld (__a_1_zext_add), a
	ld hl, 100
	call zext_add
	ld (main_r2), hl
; 26     return 0;
	ld hl, 0
	ret
lookup_zext:
; 15 s8 lookup_zext(u8 angle) {
	ld (__a_1_lookup_zext), a
; 16     return sin_lut[angle];
	ld de, sin_lut
	ld hl, (__a_1_lookup_zext)
	ld h, 0
	add hl, de
	ld a, (hl)
	ret
zext_add:
; 19 u16 zext_add(u8 a, u16 b) {
	ld (__a_2_zext_add), hl
; 20     return (u16)a + b;
	ld hl, (__a_1_zext_add)
	ld h, 0
	ex hl, de
	ld hl, (__a_2_zext_add)
	add hl, de
	ret
__bss:
sin_lut:
	ds 256
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 3
__a_1_main equ __s_main + 3
__a_2_main equ __s_main + 5
main_r1 equ __s_main + 0
__s_lookup_zext equ __static_stack + 0
__a_1_lookup_zext equ __s_lookup_zext + 0
main_r2 equ __s_main + 1
__s_zext_add equ __static_stack + 0
__a_1_zext_add equ __s_zext_add + 0
__a_2_zext_add equ __s_zext_add + 1
    savebin "tests\features\70\c8080.bin", __begin, __bss - __begin
