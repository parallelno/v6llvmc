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
; 25 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 26     g_u8r  = mul_u8 (g_u8a,  g_u8b);
	ld a, (g_u8a)
	ld (__a_1_mul_u8), a
	ld a, (g_u8b)
	call mul_u8
	ld (g_u8r), a
; 27     g_u16r = mul_u16(g_u16a, g_u16b);
	ld hl, (g_u16a)
	ld (__a_1_mul_u16), hl
	ld hl, (g_u16b)
	call mul_u16
	ld (g_u16r), hl
; 28     g_u16r = div_u16(g_u16a, g_u16b);
	ld hl, (g_u16a)
	ld (__a_1_div_u16), hl
	ld hl, (g_u16b)
	call div_u16
	ld (g_u16r), hl
; 29     g_u16r = mod_u16(g_u16a, g_u16b);
	ld hl, (g_u16a)
	ld (__a_1_mod_u16), hl
	ld hl, (g_u16b)
	call mod_u16
	ld (g_u16r), hl
; 30     g_u16r = shl_u16(g_u16a, g_u8a);
	ld hl, (g_u16a)
	ld (__a_1_shl_u16), hl
	ld a, (g_u8a)
	call shl_u16
	ld (g_u16r), hl
; 31     return 0;
	ld hl, 0
	ret
mul_u8:
; 19 uint8_t mul_u8(uint8_t a, uint8_t b)            { return a * b; }
	ld (__a_2_mul_u8), a
	ld a, (__a_1_mul_u8)
	ld d, a
	ld a, (__a_2_mul_u8)
	jp __o_mul_u8
mul_u16:
; 20 uint16_t mul_u16(uint16_t a, uint16_t b)        { return a * b; }
	ld (__a_2_mul_u16), hl
	ld hl, (__a_1_mul_u16)
	ex hl, de
	ld hl, (__a_2_mul_u16)
	jp __o_mul_u16
div_u16:
; 21 uint16_t div_u16(uint16_t a, uint16_t b)        { return a / b; }
	ld (__a_2_div_u16), hl
	ex hl, de
	ld hl, (__a_1_div_u16)
	jp __o_div_u16
mod_u16:
; 22 uint16_t mod_u16(uint16_t a, uint16_t b)        { return a % b; }
	ld (__a_2_mod_u16), hl
	ex hl, de
	ld hl, (__a_1_mod_u16)
	jp __o_mod_u16
shl_u16:
; 23 uint16_t shl_u16(uint16_t a, uint8_t  n)        { return a << n; }
	ld (__a_2_shl_u16), a
	ld hl, (__a_1_shl_u16)
	ld e, a
	ld d, 0
	jp __o_shl_16
__o_mul_u8:
; 124 void __o_mul_u8() {
; 125     asm {

        ld   hl, 0
        ld   e, d  ; de=d
        ld   d, l
        ld   c, 8
__o_mul_u8__l1:
        add  hl, hl
        add  a
        jp   nc, __o_mul_u8__l2
        add  hl, de
__o_mul_u8__l2:
        dec  c
        jp   nz, __o_mul_u8__l1
        ld   a, l

	ret
__o_mul_u16:
; 326 void __o_mul_u16() {
; 327     asm {

        ld   b, h
        ld   c, l
        ld   hl, 0
        ld   a, 17
__o_mul_u16_l1:
        dec  a
        ret  z
        add  hl, hl
        ex   hl, de
        add  hl, hl
        ex   hl, de
        jp   nc, __o_mul_u16_l1
        add  hl, bc
        jp   __o_mul_u16_l1

	ret
__o_div_u16:
; 388 void __o_div_u16() {
; 389     (void)__remainder;
; 390     asm {

        call __o_div_u16__l0
        ex   hl, de
        ld   (__remainder), hl
        ld   hl, 0
        ld   (__remainder + 2), hl
        ex   hl, de
        ret

__o_div_u16__l0:
        ex   hl, de
__o_div_u16__l:
        ld   a, h
        or   l
        ret  z
        ld   bc, 0
        push bc
__o_div_u16__l1:
        ld   a, e
        sub  l
        ld   a, d
        sbc  h
        jp   c, __o_div_u16__l2
        push hl
        add  hl, hl
        jp   nc, __o_div_u16__l1
__o_div_u16__l2:
        ld   hl, 0
__o_div_u16__l3:
        pop  bc
        ld   a, b
        or   c
        ret  z
        add  hl, hl
        push de
        ld   a, e
        sub  c
        ld   e, a
        ld   a, d
        sbc  b
        ld   d, a
        jp   c, __o_div_u16__l4
        inc  hl
        pop  bc
        jp   __o_div_u16__l3
__o_div_u16__l4:
        pop  de
        jp   __o_div_u16__l3

	ret
__o_mod_u16:
; 484 void __o_mod_u16() {
; 485     (void)__o_div_u16;
; 486     asm {

        call __o_div_u16__l0
        ex hl, de

	ret
__o_shl_16:
; 506 void __o_shl_16() {
; 507     asm {

        inc  e
__o_shl_16__l1:
        dec  e
        ret  z
        add  hl, hl
        jp   __o_shl_16__l1

	ret
__bss:
g_u8a:
	ds 1
g_u8b:
	ds 1
g_u8r:
	ds 1
g_u16a:
	ds 2
g_u16b:
	ds 2
g_u16r:
	ds 2
__remainder:
	ds 4
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_mul_u8 equ __static_stack + 0
__a_1_mul_u8 equ __s_mul_u8 + 0
__a_2_mul_u8 equ __s_mul_u8 + 1
__s_mul_u16 equ __static_stack + 0
__a_1_mul_u16 equ __s_mul_u16 + 0
__a_2_mul_u16 equ __s_mul_u16 + 2
__s_div_u16 equ __static_stack + 0
__a_1_div_u16 equ __s_div_u16 + 0
__a_2_div_u16 equ __s_div_u16 + 2
__s_mod_u16 equ __static_stack + 0
__a_1_mod_u16 equ __s_mod_u16 + 0
__a_2_mod_u16 equ __s_mod_u16 + 2
__s_shl_u16 equ __static_stack + 0
__a_1_shl_u16 equ __s_shl_u16 + 0
__a_2_shl_u16 equ __s_shl_u16 + 2
__s___o_mul_u8 equ __static_stack + 0
__s___o_mul_u16 equ __static_stack + 0
__s___o_div_u16 equ __static_stack + 0
__s___o_mod_u16 equ __static_stack + 0
__s___o_shl_16 equ __static_stack + 0
    savebin "tests\features\52\c8080.bin", __begin, __bss - __begin
