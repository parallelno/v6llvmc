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
; 26 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 27     (void)argc; (void)argv;
; 28     g_arr[0] = 1; g_arr[1] = 2; g_arr[2] = 3; g_arr[3] = 4;
	ld hl, 1
	ld (g_arr), hl
	ld hl, 2
	ld (0FFFFh & ((g_arr) + (2))), hl
	ld hl, 3
	ld (0FFFFh & ((g_arr) + (4))), hl
	ld hl, 4
	ld (0FFFFh & ((g_arr) + (6))), hl
; 29     g_arr[4] = 5; g_arr[5] = 6; g_arr[6] = 7; g_arr[7] = 8;
	ld hl, 5
	ld (0FFFFh & ((g_arr) + (8))), hl
	ld hl, 6
	ld (0FFFFh & ((g_arr) + (10))), hl
	ld hl, 7
	ld (0FFFFh & ((g_arr) + (12))), hl
	ld hl, 8
	ld (0FFFFh & ((g_arr) + (14))), hl
; 30     unsigned short r1 = sum_array(g_arr, 8);
	ld hl, g_arr
	ld (__a_1_sum_array), hl
	ld a, 8
	call sum_array
	ld (main_r1), hl
; 31     unsigned short r2 = poly(g_arr, 8);
	ld hl, g_arr
	ld (__a_1_poly), hl
	ld a, 8
	call poly
	ld (main_r2), hl
; 32     return ext_sink16(r1 + r2);
	ld hl, (main_r1)
	ex hl, de
	ld hl, (main_r2)
	add hl, de
	jp ext_sink16
sum_array:
; 5 unsigned short sum_array(const unsigned short *a, unsigned char n) {
	ld (__a_2_sum_array), a
; 6     unsigned short s = 0;
	ld hl, 0
	ld (sum_array_s), hl
; 7     unsigned char i;
; 8     for (i = 0; i < n; i++) {
	xor a
	ld (sum_array_i), a
l_0:
	ld hl, __a_2_sum_array
	cp (hl)
	jp nc, l_2
; 9         s += a[i] * 3 + 7;
	ld hl, (__a_1_sum_array)
	ex hl, de
	ld hl, (sum_array_i)
	ld h, 0
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld h, d
	ld l, e
	add hl, hl
	add hl, de
	ld de, 7
	add hl, de
	ex hl, de
	ld hl, (sum_array_s)
	add hl, de
	ld (sum_array_s), hl
	inc a
	ld (sum_array_i), a
	jp l_0
l_2:
; 10     }
; 11     return s;
	ld hl, (sum_array_s)
	ret
poly:
; 14 unsigned short poly(const unsigned short *a, unsigned char n) {
	ld (__a_2_poly), a
; 15     unsigned short s = 0;
	ld hl, 0
	ld (poly_s), hl
; 16     unsigned char i;
; 17     for (i = 0; i < n; i++) {
	xor a
	ld (poly_i), a
l_3:
	ld hl, __a_2_poly
	cp (hl)
	jp nc, l_5
; 18         unsigned short x = a[i];
	ld hl, (__a_1_poly)
	ex hl, de
	ld hl, (poly_i)
	ld h, 0
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (poly_x), hl
; 19         s += x * 5 + (x >> 1) + 3;
	ld d, h
	ld e, l
	add hl, hl
	add hl, hl
	add hl, de
	push hl
	ld hl, (poly_x)
	ld de, 1
	call __o_shr_u16
	pop de
	add hl, de
	inc hl
	inc hl
	inc hl
	ex hl, de
	ld hl, (poly_s)
	add hl, de
	ld (poly_s), hl
	ld a, (poly_i)
	inc a
	ld (poly_i), a
	jp l_3
l_5:
; 20     }
; 21     return s;
	ld hl, (poly_s)
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
g_arr:
	ds 16
__static_stack:
	ds 16
__end:
__s___init equ __static_stack + 16
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 4
__a_2_main equ __s_main + 6
main_r1 equ __s_main + 0
__s_sum_array equ __static_stack + 0
__a_1_sum_array equ __s_sum_array + 3
__a_2_sum_array equ __s_sum_array + 5
main_r2 equ __s_main + 2
__s_poly equ __static_stack + 0
__a_1_poly equ __s_poly + 5
__a_2_poly equ __s_poly + 7
__s_ext_sink16 equ __static_stack + 0
__a_1_ext_sink16 equ __s_ext_sink16 + 0
sum_array_s equ __s_sum_array + 0
sum_array_i equ __s_sum_array + 2
poly_s equ __s_poly + 0
poly_i equ __s_poly + 2
poly_x equ __s_poly + 3
__s___o_shr_u16 equ __static_stack + 0
    savebin "tests\features\51\c8080.bin", __begin, __bss - __begin
