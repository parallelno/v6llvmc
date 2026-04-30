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
; 27 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 28     (void)argc; (void)argv;
; 29     g_out = const_zero();
	call const_zero
	ld (g_out), a
; 30     clear_sink_twice();
	call clear_sink_twice
; 31     g_out = neg_or_seven(g_a, g_b);
	ld a, (g_a)
	ld (__a_1_neg_or_seven), a
	ld a, (g_b)
	call neg_or_seven
	ld (g_out), a
; 32     return 0;
	ld hl, 0
	ret
const_zero:
; 10 i8 const_zero(void) { return 0; }
	xor a
	ret
clear_sink_twice:
; 14 void clear_sink_twice(void) {
; 15     g_sink = 0;
	xor a
; 16     g_sink = 0;
	ld (g_sink), a
	ret
neg_or_seven:
; 19 i8 neg_or_seven(i8 a, i8 b) {
	ld (__a_2_neg_or_seven), a
; 20     return (a - b) < 0 ? (i8)0 : (i8)7;
	call __o_i8_to_i16
	push hl
	ld a, (__a_1_neg_or_seven)
	call __o_i8_to_i16
	pop de
	call __o_sub_16
	ld de, 0
	call __o_sub_16
	jp p, l_0
	xor a
	ret
l_0:
	ld a, 7
	ret
__o_i8_to_i16:
; 222 void __o_i8_to_i16() {
; 223     asm {

        ld   l, a
        rla
        sbc  a
        ld   h, a

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
g_a:
	db 253
g_b:
	db 4
__bss:
g_sink:
	ds 1
g_out:
	ds 1
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_neg_or_seven equ __static_stack + 0
__a_1_neg_or_seven equ __s_neg_or_seven + 0
__a_2_neg_or_seven equ __s_neg_or_seven + 1
__s_const_zero equ __static_stack + 0
__s_clear_sink_twice equ __static_stack + 0
__s___o_i8_to_i16 equ __static_stack + 0
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\46\c8080.bin", __begin, __bss - __begin
