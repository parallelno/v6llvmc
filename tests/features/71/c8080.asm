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
; 44 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 45     volatile u8  r1 = xor16_to_i8(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_xor16_to_i8), hl
	ld hl, 22136
	call xor16_to_i8
	ld (main_r1), a
; 46     volatile u8  r2 = or16_to_i8(0xA5A5, 0x5A5A);
	ld hl, 42405
	ld (__a_1_or16_to_i8), hl
	ld hl, 23130
	call or16_to_i8
	ld (main_r2), a
; 47     volatile u8  r3 = and16_to_i8(0xF0F0, 0x0F0F);
	ld hl, 61680
	ld (__a_1_and16_to_i8), hl
	ld hl, 3855
	call and16_to_i8
	ld (main_r3), a
; 48     volatile u8  r4 = xor_bytes(0x1234);
	ld hl, 4660
	call xor_bytes
	ld (main_r4), a
; 49     volatile u8  r5 = xor16_cmp_zero(0x1234, 0x1234);
	ld hl, 4660
	ld (__a_1_xor16_cmp_zero), hl
	call xor16_cmp_zero
	ld (main_r5), a
; 50     volatile u8  r6 = and16_cmp_zero(0x00FF, 0xFF00);
	ld hl, 255
	ld (__a_1_and16_cmp_zero), hl
	ld hl, 65280
	call and16_cmp_zero
	ld (main_r6), a
; 51     volatile u8  r7 = or16_cmp_zero(0x0001, 0x0000);
	ld hl, 1
	ld (__a_1_or16_cmp_zero), hl
	ld hl, 0
	call or16_cmp_zero
	ld (main_r7), a
; 52     volatile u16 r8 = xor16_full(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_xor16_full), hl
	ld hl, 22136
	call xor16_full
	ld (main_r8), hl
; 53     return 0;
	ld hl, 0
	ret
xor16_to_i8:
; 12 u8 xor16_to_i8(u16 a, u16 b) {
	ld (__a_2_xor16_to_i8), hl
; 13     return (u8)(a ^ b);
	ld a, (__a_1_xor16_to_i8)
	ld d, a
	ld a, (__a_2_xor16_to_i8)
	xor d
	ret
or16_to_i8:
; 16 u8 or16_to_i8(u16 a, u16 b) {
	ld (__a_2_or16_to_i8), hl
; 17     return (u8)(a | b);
	ld a, (__a_1_or16_to_i8)
	ld d, a
	ld a, (__a_2_or16_to_i8)
	or d
	ret
and16_to_i8:
; 20 u8 and16_to_i8(u16 a, u16 b) {
	ld (__a_2_and16_to_i8), hl
; 21     return (u8)(a & b);
	ld a, (__a_1_and16_to_i8)
	ld d, a
	ld a, (__a_2_and16_to_i8)
	and d
	ret
xor_bytes:
; 24 u8 xor_bytes(u16 a) {
	ld (__a_1_xor_bytes), hl
; 25     return (u8)((u8)a ^ (u8)(a >> 8));
	ld a, (__a_1_xor_bytes)
	ld d, h
	xor d
	ret
xor16_cmp_zero:
; 28 u8 xor16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_xor16_cmp_zero), hl
; 29     return (u8)(a ^ b) == 0;
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
; 32 u8 and16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_and16_cmp_zero), hl
; 33     return (u8)(a & b) == 0;
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
; 36 u8 or16_cmp_zero(u16 a, u16 b) {
	ld (__a_2_or16_cmp_zero), hl
; 37     return (u8)(a | b) == 0;
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
xor16_full:
; 40 u16 xor16_full(u16 a, u16 b) {
	ld (__a_2_xor16_full), hl
; 41     return a ^ b;
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
	ds 17
__end:
__s___init equ __static_stack + 17
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 9
__a_2_main equ __s_main + 11
main_r1 equ __s_main + 0
__s_xor16_to_i8 equ __static_stack + 0
__a_1_xor16_to_i8 equ __s_xor16_to_i8 + 0
__a_2_xor16_to_i8 equ __s_xor16_to_i8 + 2
main_r2 equ __s_main + 1
__s_or16_to_i8 equ __static_stack + 0
__a_1_or16_to_i8 equ __s_or16_to_i8 + 0
__a_2_or16_to_i8 equ __s_or16_to_i8 + 2
main_r3 equ __s_main + 2
__s_and16_to_i8 equ __static_stack + 0
__a_1_and16_to_i8 equ __s_and16_to_i8 + 0
__a_2_and16_to_i8 equ __s_and16_to_i8 + 2
main_r4 equ __s_main + 3
__s_xor_bytes equ __static_stack + 0
__a_1_xor_bytes equ __s_xor_bytes + 0
main_r5 equ __s_main + 4
__s_xor16_cmp_zero equ __static_stack + 0
__a_1_xor16_cmp_zero equ __s_xor16_cmp_zero + 0
__a_2_xor16_cmp_zero equ __s_xor16_cmp_zero + 2
main_r6 equ __s_main + 5
__s_and16_cmp_zero equ __static_stack + 0
__a_1_and16_cmp_zero equ __s_and16_cmp_zero + 0
__a_2_and16_cmp_zero equ __s_and16_cmp_zero + 2
main_r7 equ __s_main + 6
__s_or16_cmp_zero equ __static_stack + 0
__a_1_or16_cmp_zero equ __s_or16_cmp_zero + 0
__a_2_or16_cmp_zero equ __s_or16_cmp_zero + 2
main_r8 equ __s_main + 7
__s_xor16_full equ __static_stack + 0
__a_1_xor16_full equ __s_xor16_full + 0
__a_2_xor16_full equ __s_xor16_full + 2
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\71\c8080.bin", __begin, __bss - __begin
