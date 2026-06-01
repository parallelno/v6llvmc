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
; 49 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 50     volatile u8  r1 = p1_lo_byte_after_xor16(0x1234);
	ld hl, 4660
	call p1_lo_byte_after_xor16
	ld (main_r1), a
; 51     volatile u8  r2 = p2_hi_byte_after_xor16(0x5678);
	ld hl, 22136
	call p2_hi_byte_after_xor16
	ld (main_r2), a
; 52     volatile u8  r3 = p3_standalone_lo();
	call p3_standalone_lo
	ld (main_r3), a
; 53     volatile u8  r4 = p4_standalone_hi();
	call p4_standalone_hi
	ld (main_r4), a
; 54     volatile u16 r5 = p5_both_bytes_used(0xABCD);
	ld hl, 43981
	call p5_both_bytes_used
	ld (main_r5), hl
; 55     return 0;
	ld hl, 0
	ret
p1_lo_byte_after_xor16:
; 17 u8 p1_lo_byte_after_xor16(u16 a) {
	ld (__a_1_p1_lo_byte_after_xor16), hl
; 18     const u16 mask = 0xB4FF;
	ld hl, 46335
	ld (p1_lo_byte_after_xor16_mask), hl
; 19     g_sink16 = a ^ mask;
	ld hl, (__a_1_p1_lo_byte_after_xor16)
	ex hl, de
	ld hl, (p1_lo_byte_after_xor16_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 20     return (u8)(mask);
	ld a, (p1_lo_byte_after_xor16_mask)
	ret
p2_hi_byte_after_xor16:
; 24 u8 p2_hi_byte_after_xor16(u16 a) {
	ld (__a_1_p2_hi_byte_after_xor16), hl
; 25     const u16 mask = 0xB4FF;
	ld hl, 46335
	ld (p2_hi_byte_after_xor16_mask), hl
; 26     g_sink16 = a ^ mask;
	ld hl, (__a_1_p2_hi_byte_after_xor16)
	ex hl, de
	ld hl, (p2_hi_byte_after_xor16_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 27     return (u8)(mask >> 8);
	ld hl, (p2_hi_byte_after_xor16_mask)
	ld a, h
	ret
p3_standalone_lo:
; 31 u8 p3_standalone_lo() {
; 32     const u16 k = 0x1234;
	ld hl, 4660
	ld (p3_standalone_lo_k), hl
; 33     return (u8)(k);
	ld a, (p3_standalone_lo_k)
	ret
p4_standalone_hi:
; 37 u8 p4_standalone_hi() {
; 38     const u16 k = 0x1234;
	ld hl, 4660
	ld (p4_standalone_hi_k), hl
; 39     return (u8)(k >> 8);
	ld a, h
	ret
p5_both_bytes_used:
; 43 u16 p5_both_bytes_used(u16 a) {
	ld (__a_1_p5_both_bytes_used), hl
; 44     const u16 mask = 0xB4FF;
	ld hl, 46335
	ld (p5_both_bytes_used_mask), hl
; 45     g_sink16 = a ^ mask;
	ld hl, (__a_1_p5_both_bytes_used)
	ex hl, de
	ld hl, (p5_both_bytes_used_mask)
	call __o_xor_16
	ld (g_sink16), hl
; 46     return mask;
	ld hl, (p5_both_bytes_used_mask)
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
__static_stack:
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 6
__a_2_main equ __s_main + 8
main_r1 equ __s_main + 0
__s_p1_lo_byte_after_xor16 equ __static_stack + 0
__a_1_p1_lo_byte_after_xor16 equ __s_p1_lo_byte_after_xor16 + 2
main_r2 equ __s_main + 1
__s_p2_hi_byte_after_xor16 equ __static_stack + 0
__a_1_p2_hi_byte_after_xor16 equ __s_p2_hi_byte_after_xor16 + 2
main_r3 equ __s_main + 2
main_r4 equ __s_main + 3
main_r5 equ __s_main + 4
__s_p5_both_bytes_used equ __static_stack + 0
__a_1_p5_both_bytes_used equ __s_p5_both_bytes_used + 2
p1_lo_byte_after_xor16_mask equ __s_p1_lo_byte_after_xor16 + 0
p2_hi_byte_after_xor16_mask equ __s_p2_hi_byte_after_xor16 + 0
__s_p3_standalone_lo equ __static_stack + 0
p3_standalone_lo_k equ __s_p3_standalone_lo + 0
__s_p4_standalone_hi equ __static_stack + 0
p4_standalone_hi_k equ __s_p4_standalone_hi + 0
p5_both_bytes_used_mask equ __s_p5_both_bytes_used + 0
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\74\c8080.bin", __begin, __bss - __begin
