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
; 47 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 48     volatile u16 r1 = xor16_const(0x1234);
	ld hl, 4660
	call xor16_const
	ld (main_r1), hl
; 49     volatile u16 r2 = xor16_hi_only(0x1234);
	ld hl, 4660
	call xor16_hi_only
	ld (main_r2), hl
; 50     volatile u16 r3 = or16_lo_only(0x1234);
	ld hl, 4660
	call or16_lo_only
	ld (main_r3), hl
; 51     volatile u16 r4 = and16_clear_lo(0x1234);
	ld hl, 4660
	call and16_clear_lo
	ld (main_r4), hl
; 52     volatile u16 r5 = and16_mask(0x1234);
	ld hl, 4660
	call and16_mask
	ld (main_r5), hl
; 53     volatile u16 r6 = or16_set_all(0x1234);
	ld hl, 4660
	call or16_set_all
	ld (main_r6), hl
; 54     volatile u16 r7 = lfsr_run(0xACE1, 16);
	ld hl, 44257
	ld (__a_1_lfsr_run), hl
	ld a, 16
	call lfsr_run
	ld (main_r7), hl
; 55     return 0;
	ld hl, 0
	ret
xor16_const:
; 11 u16 xor16_const(u16 x) {
	ld (__a_1_xor16_const), hl
; 12     return x ^ 0xB43C;
	ld de, 0
	push de
	push hl
	ld hl, 46140
	call __o_xor_32
	ret
xor16_hi_only:
; 15 u16 xor16_hi_only(u16 x) {
	ld (__a_1_xor16_hi_only), hl
; 16     return x ^ 0xB400;
	ld de, 0
	push de
	push hl
	ld hl, 46080
	call __o_xor_32
	ret
or16_lo_only:
; 19 u16 or16_lo_only(u16 x) {
	ld (__a_1_or16_lo_only), hl
; 20     return x | 0x0080;
	ld de, 128
	jp __o_or_16
and16_clear_lo:
; 23 u16 and16_clear_lo(u16 x) {
	ld (__a_1_and16_clear_lo), hl
; 24     return x & 0xFF00;
	ld de, 0
	push de
	push hl
	ld hl, 65280
	call __o_and_32
	ret
and16_mask:
; 27 u16 and16_mask(u16 x) {
	ld (__a_1_and16_mask), hl
; 28     return x & 0xF00F;
	ld de, 0
	push de
	push hl
	ld hl, 61455
	call __o_and_32
	ret
or16_set_all:
; 31 u16 or16_set_all(u16 x) {
	ld (__a_1_or16_set_all), hl
; 32     return x | 0xFFFF;
	ld de, 0
	push de
	push hl
	ld hl, 65535
	call __o_or_32
	ret
lfsr_run:
; 35 u16 lfsr_run(u16 seed, u8 steps) {
	ld (__a_2_lfsr_run), a
; 36     u16 x = seed;
	ld hl, (__a_1_lfsr_run)
	ld (lfsr_run_x), hl
; 37     u8 i;
; 38     for (i = 0; i < steps; i++) {
	xor a
	ld (lfsr_run_i), a
l_0:
	ld hl, __a_2_lfsr_run
	cp (hl)
	jp nc, l_2
; 39         if (x & 1)
	ld hl, (lfsr_run_x)
	ld de, 1
	call __o_and_16
	ld a, h
	or l
	jp z, l_3
; 40             x = (x >> 1) ^ 0xB400;
	ld hl, (lfsr_run_x)
	ld de, 1
	call __o_shr_u16
	ld de, 0
	push de
	push hl
	ld hl, 46080
	call __o_xor_32
	ld (lfsr_run_x), hl
	jp l_4
l_3:
; 41         else
; 42             x = x >> 1;
	ld hl, (lfsr_run_x)
	ld de, 1
	call __o_shr_u16
	ld (lfsr_run_x), hl
l_4:
	ld a, (lfsr_run_i)
	inc a
	ld (lfsr_run_i), a
	jp l_0
l_2:
; 43     }
; 44     return x;
	ld hl, (lfsr_run_x)
	ret
__o_xor_32:
; 766 void __o_xor_32() {
; 767     asm {

        ld   bc, hl    ; bc = v1l
        pop  hl        ; hl = ret, stack = v2l
        ex   (sp), hl  ; hl = v2l, stack = ret
        ld   a, c
        xor  l
        ld   c, a
        ld   a, b
        xor  h
        ld   b, a      ; bc - result
        pop  hl        ; hl = ret, stack = v2h
        ex   (sp), hl  ; hl = v2h, stack = ret
        ld   a, e
        xor  l
        ld   e, a
        ld   a, d
        xor  h
        ld   d, a      ; de - result
        ld   hl, bc

	ret
__o_or_16:
; 295 void __o_or_16() {
; 296     asm {

        ld   a, h
        or   d
        ld   h, a
        ld   a, l
        or   e
        ld   l, a

	ret
__o_and_32:
; 712 void __o_and_32() {
; 713     asm {

        ld   bc, hl    ; bc = v1l
        pop  hl        ; hl = ret, stack = v2l
        ex   (sp), hl  ; hl = v2l, stack = ret
        ld   a, c
        and  l
        ld   c, a
        ld   a, b
        and  h
        ld   b, a      ; bc - result
        pop  hl        ; hl = ret, stack = v2h
        ex   (sp), hl  ; hl = v2h, stack = ret
        ld   a, e
        and  l
        ld   e, a
        ld   a, d
        and  h
        ld   d, a      ; de - result
        ld   hl, bc

	ret
__o_or_32:
; 739 void __o_or_32() {
; 740     asm {

        ld   bc, hl    ; bc = v1l
        pop  hl        ; hl = ret, stack = v2l
        ex   (sp), hl  ; hl = v2l, stack = ret
        ld   a, c
        or   l
        ld   c, a
        ld   a, b
        or   h
        ld   b, a      ; bc - result
        pop  hl        ; hl = ret, stack = v2h
        ex   (sp), hl  ; hl = v2h, stack = ret
        ld   a, e
        or   l
        ld   e, a
        ld   a, d
        or   h
        ld   d, a      ; de - result
        ld   hl, bc

	ret
__o_and_16:
; 280 void __o_and_16() {
; 281     asm {

        ld   a, h
        and  d
        ld   h, a
        ld   a, l
        and  e
        ld   l, a

	ret
__o_shr_u16:
; 521 void __o_shr_u16() {
; 522     asm {

        inc  e
__o_shr_u16__l1:
        dec  e
        ret  z
        ld   a, h
        or   a    ; cf = 0
        rra
        ld   h, a
        ld   a, l
        rra
        ld   l, a
        jp   __o_shr_u16__l1
1

	ret
__bss:
__static_stack:
	ds 24
__end:
__s___init equ __static_stack + 24
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 14
__a_2_main equ __s_main + 16
main_r1 equ __s_main + 0
__s_xor16_const equ __static_stack + 0
__a_1_xor16_const equ __s_xor16_const + 0
main_r2 equ __s_main + 2
__s_xor16_hi_only equ __static_stack + 0
__a_1_xor16_hi_only equ __s_xor16_hi_only + 0
main_r3 equ __s_main + 4
__s_or16_lo_only equ __static_stack + 0
__a_1_or16_lo_only equ __s_or16_lo_only + 0
main_r4 equ __s_main + 6
__s_and16_clear_lo equ __static_stack + 0
__a_1_and16_clear_lo equ __s_and16_clear_lo + 0
main_r5 equ __s_main + 8
__s_and16_mask equ __static_stack + 0
__a_1_and16_mask equ __s_and16_mask + 0
main_r6 equ __s_main + 10
__s_or16_set_all equ __static_stack + 0
__a_1_or16_set_all equ __s_or16_set_all + 0
main_r7 equ __s_main + 12
__s_lfsr_run equ __static_stack + 0
__a_1_lfsr_run equ __s_lfsr_run + 3
__a_2_lfsr_run equ __s_lfsr_run + 5
lfsr_run_x equ __s_lfsr_run + 0
lfsr_run_i equ __s_lfsr_run + 2
__s___o_xor_32 equ __static_stack + 0
__s___o_or_16 equ __static_stack + 0
__s___o_and_32 equ __static_stack + 0
__s___o_or_32 equ __static_stack + 0
__s___o_and_16 equ __static_stack + 0
__s___o_shr_u16 equ __static_stack + 0
    savebin "tests\features\77\c8080.bin", __begin, __bss - __begin
