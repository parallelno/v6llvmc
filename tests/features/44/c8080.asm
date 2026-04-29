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
; 15 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 16     (void)argc; (void)argv;
; 17     g_out = rotl1(g_in);
	ld a, (g_in)
	call rotl1
	ld (g_out), a
; 18     g_out = rotr1(g_in);
	ld a, (g_in)
	call rotr1
	ld (g_out), a
; 19     g_out = rotl3(g_in);
	ld a, (g_in)
	call rotl3
	ld (g_out), a
; 20     g_out = rotr3(g_in);
	ld a, (g_in)
	call rotr3
	ld (g_out), a
; 21     g_out = rotl7(g_in);
	ld a, (g_in)
	call rotl7
	ld (g_out), a
; 22     g_out = rotl4(g_in);
	ld a, (g_in)
	call rotl4
	ld (g_out), a
; 23     return 0;
	ld hl, 0
	ret
rotl1:
; 5 u8 rotl1(u8 x) { return (u8)((x << 1) | (x >> 7)); }
	ld (__a_1_rotl1), a
	add a
	ld d, a
	ld a, (__a_1_rotl1)
	rlca
	and 1
	or d
	ret
rotr1:
; 6 u8 rotr1(u8 x) { return (u8)((x >> 1) | (x << 7)); }
	ld (__a_1_rotr1), a
	and a
	rra
	ld d, a
	ld a, (__a_1_rotr1)
	rrca
	and 1
	or d
	ret
rotl3:
; 7 u8 rotl3(u8 x) { return (u8)((x << 3) | (x >> 5)); }
	ld (__a_1_rotl3), a
	add a
	add a
	add a
	ld d, a
	ld a, (__a_1_rotl3)
	rlca
	rlca
	rlca
	and 7
	or d
	ret
rotr3:
; 8 u8 rotr3(u8 x) { return (u8)((x >> 3) | (x << 5)); }
	ld (__a_1_rotr3), a
	rrca
	rrca
	rrca
	and 31
	ld d, a
	ld a, (__a_1_rotr3)
	add a
	add a
	add a
	add a
	add a
	or d
	ret
rotl7:
; 9 u8 rotl7(u8 x) { return (u8)((x << 7) | (x >> 1)); }
	ld (__a_1_rotl7), a
	rrca
	and 1
	ld d, a
	ld a, (__a_1_rotl7)
	and a
	rra
	or d
	ret
rotl4:
; 10 u8 rotl4(u8 x) { return (u8)((x << 4) | (x >> 4)); }
	ld (__a_1_rotl4), a
	add a
	add a
	add a
	add a
	ld d, a
	ld a, (__a_1_rotl4)
	rrca
	rrca
	rrca
	rrca
	and 15
	or d
	ret
g_in:
	db 90
__bss:
g_out:
	ds 1
__static_stack:
	ds 5
__end:
__s___init equ __static_stack + 5
__s_main equ __static_stack + 1
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_rotl1 equ __static_stack + 0
__a_1_rotl1 equ __s_rotl1 + 0
__s_rotr1 equ __static_stack + 0
__a_1_rotr1 equ __s_rotr1 + 0
__s_rotl3 equ __static_stack + 0
__a_1_rotl3 equ __s_rotl3 + 0
__s_rotr3 equ __static_stack + 0
__a_1_rotr3 equ __s_rotr3 + 0
__s_rotl7 equ __static_stack + 0
__a_1_rotl7 equ __s_rotl7 + 0
__s_rotl4 equ __static_stack + 0
__a_1_rotl4 equ __s_rotl4 + 0
    savebin "tests\features\44\c8080.bin", __begin, __bss - __begin
