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
; 36 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 37     volatile u8  r1 = xor16_cmp_zero(0x1234, 0x1234);
	ld hl, 4660
	ld (__a_1_xor16_cmp_zero), hl
	call xor16_cmp_zero
	ld (main_r1), a
; 38     volatile u8  r2 = and16_cmp_zero(0x00FF, 0xFF00);
	ld hl, 255
	ld (__a_1_and16_cmp_zero), hl
	ld hl, 65280
	call and16_cmp_zero
	ld (main_r2), a
; 39     volatile u8  r3 = or16_cmp_zero(0x0001, 0x0000);
	ld hl, 1
	ld (__a_1_or16_cmp_zero), hl
	ld hl, 0
	call or16_cmp_zero
	ld (main_r3), a
; 40     volatile u8  r4 = xor16_to_i8(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_xor16_to_i8), hl
	ld hl, 22136
	call xor16_to_i8
	ld (main_r4), a
; 41     volatile u16 r5 = xor16_full(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_xor16_full), hl
	ld hl, 22136
	call xor16_full
	ld (main_r5), hl
; 42     return 0;
	ld hl, 0
	ret
xor16_cmp_zero:
; 12 u8 xor16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_xor16_cmp_zero), hl
; 13     return (u8)(a ^ b) == 0;
	ld a, (__a_1_xor16_cmp_zero)
	ld d, a
	ld a, (__a_2_xor16_cmp_zero)
	xor d
	jp nz, l_0
	ld a, 1
	ret
l_0:
	xor a
	ret
and16_cmp_zero:
; 17 u8 and16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_and16_cmp_zero), hl
; 18     return (u8)(a & b) == 0;
	ld a, (__a_1_and16_cmp_zero)
	ld d, a
	ld a, (__a_2_and16_cmp_zero)
	and d
	jp nz, l_2
	ld a, 1
	ret
l_2:
	xor a
	ret
or16_cmp_zero:
; 22 u8 or16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_or16_cmp_zero), hl
; 23     return (u8)(a | b) == 0;
	ld a, (__a_1_or16_cmp_zero)
	ld d, a
	ld a, (__a_2_or16_cmp_zero)
	or d
	jp nz, l_4
	ld a, 1
	ret
l_4:
	xor a
	ret
xor16_to_i8:
; 27 u8 xor16_to_i8(u16 a, u16 b) {
	ld (__a_2_xor16_to_i8), hl
; 28     return (u8)(a ^ b);
	ld a, (__a_1_xor16_to_i8)
	ld d, a
	ld a, (__a_2_xor16_to_i8)
	xor d
	ret
xor16_full:
; 32 u16 xor16_full(u16 a, u16 b) {
	ld (__a_2_xor16_full), hl
; 33     return a ^ b;
	ld hl, (__a_1_xor16_full)
	ex hl, de
	ld hl, (__a_2_xor16_full)
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
__bss:
__static_stack:
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 6
__a_2_main equ __s_main + 8
main_r1 equ __s_main + 0
__s_xor16_cmp_zero equ __static_stack + 0
__a_1_xor16_cmp_zero equ __s_xor16_cmp_zero + 0
__a_2_xor16_cmp_zero equ __s_xor16_cmp_zero + 2
main_r2 equ __s_main + 1
__s_and16_cmp_zero equ __static_stack + 0
__a_1_and16_cmp_zero equ __s_and16_cmp_zero + 0
__a_2_and16_cmp_zero equ __s_and16_cmp_zero + 2
main_r3 equ __s_main + 2
__s_or16_cmp_zero equ __static_stack + 0
__a_1_or16_cmp_zero equ __s_or16_cmp_zero + 0
__a_2_or16_cmp_zero equ __s_or16_cmp_zero + 2
main_r4 equ __s_main + 3
__s_xor16_to_i8 equ __static_stack + 0
__a_1_xor16_to_i8 equ __s_xor16_to_i8 + 0
__a_2_xor16_to_i8 equ __s_xor16_to_i8 + 2
main_r5 equ __s_main + 4
__s_xor16_full equ __static_stack + 0
__a_1_xor16_full equ __s_xor16_full + 0
__a_2_xor16_full equ __s_xor16_full + 2
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\73\c8080.bin", __begin, __bss - __begin
