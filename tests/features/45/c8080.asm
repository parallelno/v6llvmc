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
; 29 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 30     (void)argc; (void)argv;
; 31     g_out = rotl_u16_1(g_in);
	ld hl, (g_in)
	call rotl_u16_1
	ld (g_out), hl
; 32     g_out = crc16_step(g_in, g_byte);
	ld hl, (g_in)
	ld (__a_1_crc16_step), hl
	ld a, (g_byte)
	call crc16_step
	ld (g_out), hl
; 33     g_out = rotl_u16_2(g_in);
	ld hl, (g_in)
	call rotl_u16_2
	ld (g_out), hl
; 34     g_out = fshl_u16_1(g_in);
	ld hl, (g_in)
	call fshl_u16_1
	ld (g_out), hl
; 35     return 0;
	ld hl, 0
	ret
rotl_u16_1:
; 7 u16 rotl_u16_1(u16 x) { return (u16)((x << 1) | (x >> 15)); }
	ld (__a_1_rotl_u16_1), hl
	ld de, 15
	call __o_shr_u16
	ex hl, de
	ld hl, (__a_1_rotl_u16_1)
	add hl, hl
	jp __o_or_16
crc16_step:
; 9 u16 crc16_step(u16 crc, u8 byte) {
	ld (__a_2_crc16_step), a
; 10     crc ^= ((u16)byte) << 8;
	ld hl, (__a_1_crc16_step)
	ex hl, de
	ld hl, (__a_2_crc16_step)
	ld h, 0
	ld h, l
	ld l, 0
	call __o_xor_16
	ld (__a_1_crc16_step), hl
; 11     for (int i = 0; i < 8; ++i) {
	ld hl, 0
	ld (crc16_step_i), hl
l_0:
	ld de, 8
	call __o_sub_16
	jp p, l_2
; 12         u16 hi = crc & 0x8000;
	ld hl, (__a_1_crc16_step)
	ld de, 0
	push de
	push hl
	ld hl, 32768
	call __o_and_32
	ld (crc16_step_hi), hl
; 13         crc = (u16)(crc << 1);
	ld hl, (__a_1_crc16_step)
	add hl, hl
	ld (__a_1_crc16_step), hl
; 14         if (hi) crc ^= 0x1021;
	ld hl, (crc16_step_hi)
	ld a, h
	or l
	jp z, l_3
	ld hl, (__a_1_crc16_step)
	ld de, 4129
	call __o_xor_16
	ld (__a_1_crc16_step), hl
l_3:
	ld hl, (crc16_step_i)
	inc hl
	ld (crc16_step_i), hl
	jp l_0
l_2:
; 15     }
; 16     return crc;
	ld hl, (__a_1_crc16_step)
	ret
rotl_u16_2:
; 19 u16 rotl_u16_2(u16 x) { return (u16)((x << 2) | (x >> 14)); }
	ld (__a_1_rotl_u16_2), hl
	ld de, 14
	call __o_shr_u16
	ex hl, de
	ld hl, (__a_1_rotl_u16_2)
	add hl, hl
	add hl, hl
	jp __o_or_16
fshl_u16_1:
; 23 u16 fshl_u16_1(u16 x) { return (u16)((x << 1) | (x >> 15)); }
	ld (__a_1_fshl_u16_1), hl
	ld de, 15
	call __o_shr_u16
	ex hl, de
	ld hl, (__a_1_fshl_u16_1)
	add hl, hl
	jp __o_or_16
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
__o_sub_16:
; 265 void __o_sub_16() {
; 266     asm {

        ld   a, l
        sub  e
        ld   l, a
        ld   a, h
        sbc  d
        ld   h, a

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
g_in:
	dw 4660
g_byte:
	db 90
__bss:
g_out:
	ds 2
__static_stack:
	ds 11
__end:
__s___init equ __static_stack + 11
__s_main equ __static_stack + 7
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_rotl_u16_1 equ __static_stack + 0
__a_1_rotl_u16_1 equ __s_rotl_u16_1 + 0
__s_crc16_step equ __static_stack + 0
__a_1_crc16_step equ __s_crc16_step + 4
__a_2_crc16_step equ __s_crc16_step + 6
__s_rotl_u16_2 equ __static_stack + 0
__a_1_rotl_u16_2 equ __s_rotl_u16_2 + 0
__s_fshl_u16_1 equ __static_stack + 0
__a_1_fshl_u16_1 equ __s_fshl_u16_1 + 0
crc16_step_i equ __s_crc16_step + 0
crc16_step_hi equ __s_crc16_step + 2
__s___o_shr_u16 equ __static_stack + 0
__s___o_or_16 equ __static_stack + 0
__s___o_xor_16 equ __static_stack + 0
__s___o_sub_16 equ __static_stack + 0
__s___o_and_32 equ __static_stack + 0
    savebin "c8080.bin", __begin, __bss - __begin
