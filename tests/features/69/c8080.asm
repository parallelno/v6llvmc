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
; 18 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 19   (void)argc;
; 20   (void)argv;
; 21 
; 22   out_i16 = neg_i16_unary(g_i16);
	ld hl, (g_i16)
	call neg_i16_unary
	ld (out_i16), hl
; 23   out_i16 = neg_i16_mul_left(g_i16);
	ld hl, (g_i16)
	call neg_i16_mul_left
	ld (out_i16), hl
; 24   out_i16 = neg_i16_mul_right(g_i16);
	ld hl, (g_i16)
	call neg_i16_mul_right
	ld (out_i16), hl
; 25   out_i16 = neg_i16_global_unary();
	call neg_i16_global_unary
	ld (out_i16), hl
; 26 
; 27   out_i8 = neg_i8_unary(g_i8);
	ld a, (g_i8)
	call neg_i8_unary
	ld (out_i8), a
; 28   out_i8 = neg_i8_global_unary();
	call neg_i8_global_unary
	ld (out_i8), a
; 29   return 0;
	ld hl, 0
	ret
neg_i16_unary:
; 9 s16 neg_i16_unary(s16 x) { return -x; }
	ld (__a_1_neg_i16_unary), hl
	jp __o_minus_16
neg_i16_mul_left:
; 10 s16 neg_i16_mul_left(s16 x) { return (s16)(-1) * x; }
	ld (__a_1_neg_i16_mul_left), hl
	ld de, 65535
	jp __o_mul_i16
neg_i16_mul_right:
; 11 s16 neg_i16_mul_right(s16 x) { return x * (s16)(-1); }
	ld (__a_1_neg_i16_mul_right), hl
	ld de, 65535
	jp __o_mul_i16
neg_i16_global_unary:
; 15 s16 neg_i16_global_unary(void) { return -g_i16; }
	ld hl, (g_i16)
	jp __o_minus_16
neg_i8_unary:
; 13 s8 neg_i8_unary(s8 x) { return -x; }
	ld (__a_1_neg_i8_unary), a
	cpl
	inc a
	ret
neg_i8_global_unary:
; 16 s8 neg_i8_global_unary(void) { return -g_i8; }
	ld a, (g_i8)
	cpl
	inc a
	ret
__o_minus_16:
; 235 void __o_minus_16() {
; 236     asm {

        xor  a
        sub  l
        ld   l, a
        ld   a, 0
        sbc  h
        ld  h, a

	ret
__o_mul_i16:
; 349 void __o_mul_i16() {
; 350     (void)__o_minus_16;
; 351     (void)__o_mul_u16;
; 352     asm {

        ld   a, h
        add  a
        jp   nc, __o_mul_i16_1  ; hl - positive

        call __o_minus_16

        ld   a, d
        add  a
        jp   nc, __o_mul_i16_2  ; hl - negative, de - positive

        ex   hl, de
        call __o_minus_16
        ex   hl, de

        jp   __o_mul_u16 ; hl & de - negative

__o_mul_i16_1:
        ld   a, d
        add  a
        jp   nc, __o_mul_u16  ; hl & de - positive

        ex   hl, de
        call __o_minus_16
        ex   hl, de

__o_mul_i16_2:
        call __o_mul_u16
        jp   __o_minus_16

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
g_i16:
	dw 33059
g_i8:
	db 147
__bss:
out_i16:
	ds 2
out_i8:
	ds 1
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_neg_i16_unary equ __static_stack + 0
__a_1_neg_i16_unary equ __s_neg_i16_unary + 0
__s_neg_i16_mul_left equ __static_stack + 0
__a_1_neg_i16_mul_left equ __s_neg_i16_mul_left + 0
__s_neg_i16_mul_right equ __static_stack + 0
__a_1_neg_i16_mul_right equ __s_neg_i16_mul_right + 0
__s_neg_i8_unary equ __static_stack + 0
__a_1_neg_i8_unary equ __s_neg_i8_unary + 0
__s_neg_i16_global_unary equ __static_stack + 0
__s_neg_i8_global_unary equ __static_stack + 0
__s___o_minus_16 equ __static_stack + 0
__s___o_mul_i16 equ __static_stack + 0
__s___o_mul_u16 equ __static_stack + 0
    savebin "tests\features\69\c8080.bin", __begin, __bss - __begin
