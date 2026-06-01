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
; 41 int main(int argc, char** argv) {
	ld (__a_2_main), hl
; 42     g_sink8 = lxi_lo_used(0x1234);
	ld hl, 4660
	call lxi_lo_used
	ld (g_sink8), a
; 43     g_sink8 = lxi_hi_used(0x5678);
	ld hl, 22136
	call lxi_hi_used
	ld (g_sink8), a
; 44     g_sink16 = lxi_lo_to_b(0x9abc);
	ld hl, 39612
	call lxi_lo_to_b
	ld (g_sink16), hl
; 45     g_sink8 = lxi_lo_zero(0xdef0);
	ld hl, 57072
	call lxi_lo_zero
	ld (g_sink8), a
; 46     return 0;
	ld hl, 0
	ret
lxi_lo_used:
; 13 u8 lxi_lo_used(u16 x) {
	ld (__a_1_lxi_lo_used), hl
; 14     u16 mask;
; 15     mask = 0xB4FF;
	ld hl, 46335
	ld (lxi_lo_used_mask), hl
; 16     g_sink16 = x ^ mask;
	ld hl, (__a_1_lxi_lo_used)
	ex hl, de
	ld hl, (lxi_lo_used_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 17     return (u8)(mask & 0xFF);
	ld a, (lxi_lo_used_mask)
	and 255
	ret
lxi_hi_used:
; 20 u8 lxi_hi_used(u16 x) {
	ld (__a_1_lxi_hi_used), hl
; 21     u16 mask;
; 22     mask = 0xB4FF;
	ld hl, 46335
	ld (lxi_hi_used_mask), hl
; 23     g_sink16 = x ^ mask;
	ld hl, (__a_1_lxi_hi_used)
	ex hl, de
	ld hl, (lxi_hi_used_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 24     return (u8)(mask >> 8);
	ld hl, (lxi_hi_used_mask)
	ld a, h
	ret
lxi_lo_to_b:
; 27 u16 lxi_lo_to_b(u16 x) {
	ld (__a_1_lxi_lo_to_b), hl
; 28     u16 mask;
; 29     mask = 0x9A37;
	ld hl, 39479
	ld (lxi_lo_to_b_mask), hl
; 30     g_sink16 = x ^ mask;
	ld hl, (__a_1_lxi_lo_to_b)
	ex hl, de
	ld hl, (lxi_lo_to_b_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 31     return (u16)((u8)(mask & 0xFF));
	ld a, (lxi_lo_to_b_mask)
	and 255
	ld l, a
	ld h, 0
	ret
lxi_lo_zero:
; 34 u8 lxi_lo_zero(u16 x) {
	ld (__a_1_lxi_lo_zero), hl
; 35     u16 mask;
; 36     mask = 0xB400;
	ld hl, 46080
	ld (lxi_lo_zero_mask), hl
; 37     g_sink16 = x ^ mask;
	ld hl, (__a_1_lxi_lo_zero)
	ex hl, de
	ld hl, (lxi_lo_zero_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 38     return (u8)(mask & 0xFF);
	ld a, (lxi_lo_zero_mask)
	and 255
	ret
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
g_sink16:
	ds 2
g_sink8:
	ds 1
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_lxi_lo_used equ __static_stack + 0
__a_1_lxi_lo_used equ __s_lxi_lo_used + 2
__s_lxi_hi_used equ __static_stack + 0
__a_1_lxi_hi_used equ __s_lxi_hi_used + 2
__s_lxi_lo_to_b equ __static_stack + 0
__a_1_lxi_lo_to_b equ __s_lxi_lo_to_b + 2
__s_lxi_lo_zero equ __static_stack + 0
__a_1_lxi_lo_zero equ __s_lxi_lo_zero + 2
lxi_lo_used_mask equ __s_lxi_lo_used + 0
lxi_hi_used_mask equ __s_lxi_hi_used + 0
lxi_lo_to_b_mask equ __s_lxi_lo_to_b + 0
lxi_lo_zero_mask equ __s_lxi_lo_zero + 0
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\75\c8080.bin", __begin, __bss - __begin
