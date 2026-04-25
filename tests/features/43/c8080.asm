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
; 50     (void)argc; (void)argv;
; 51     seed();
	call seed
; 52     axpy3(OUT, A, B, C, N);
	ld hl, out
	ld (__a_1_axpy3), hl
	ld hl, a_0
	ld (__a_2_axpy3), hl
	ld hl, b_1
	ld (__a_3_axpy3), hl
	ld hl, c_2
	ld (__a_4_axpy3), hl
	ld hl, 8
	call axpy3
; 53     g_dot = dot(A, B, N);
	ld hl, a_0
	ld (__a_1_dot), hl
	ld hl, b_1
	ld (__a_2_dot), hl
	ld hl, 8
	call dot
	ld (g_dot), hl
; 54     scale_copy(D1, D2, N);
	ld hl, d1
	ld (__a_1_scale_copy), hl
	ld hl, d2
	ld (__a_2_scale_copy), hl
	ld hl, 8
	call scale_copy
; 55     return OUT[0] + g_dot + D1[0];
	ld hl, (out)
	ex hl, de
	ld hl, (g_dot)
	add hl, de
	ex hl, de
	ld hl, (d1)
	add hl, de
	ret
seed:
; 38 void seed(void) {
; 39     unsigned i;
; 40     for (i = 0; i < N; i = i + 1) {
	ld hl, 0
	ld (seed_i), hl
l_0:
	ld de, 65528
	add hl, de
	ret c
; 41         A[i] = (int)i;
	ld de, a_0
	ld hl, (seed_i)
	add hl, hl
	add hl, de
	ex hl, de
	ld hl, (seed_i)
	ex hl, de
	ld (hl), e
	inc hl
	ld (hl), d
; 42         B[i] = (int)(i + 1);
	ld de, b_1
	ld hl, (seed_i)
	add hl, hl
	add hl, de
	ex hl, de
	ld hl, (seed_i)
	inc hl
	ex hl, de
	ld (hl), e
	inc hl
	ld (hl), d
; 43         C[i] = (int)(i + 2);
	ld de, c_2
	ld hl, (seed_i)
	add hl, hl
	add hl, de
	ex hl, de
	ld hl, (seed_i)
	inc hl
	inc hl
	ex hl, de
	ld (hl), e
	inc hl
	ld (hl), d
; 44         D1[i] = 0;
	ld de, d1
	ld hl, (seed_i)
	add hl, hl
	add hl, de
	ld de, 0
	ld (hl), e
	inc hl
	ld (hl), d
; 45         D2[i] = 0;
	ld de, d2
	ld hl, (seed_i)
	add hl, hl
	add hl, de
	ld de, 0
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (seed_i)
	inc hl
	ld (seed_i), hl
	jp l_0
axpy3:
; 14 void axpy3(int *out, int *a, int *b, int *c, unsigned n) {
	ld (__a_5_axpy3), hl
; 15     unsigned i;
; 16     for (i = 0; i < n; i = i + 1) {
	ld hl, 0
	ld (axpy3_i), hl
l_3:
	ld hl, (__a_5_axpy3)
	ex hl, de
	ld hl, (axpy3_i)
	call __o_sub_16
	ret nc
; 17         out[i] = a[i] + b[i] + c[i];
	ld hl, (__a_2_axpy3)
	ex hl, de
	ld hl, (axpy3_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de
	ld hl, (__a_3_axpy3)
	ex hl, de
	ld hl, (axpy3_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	pop de
	add hl, de
	push hl
	ld hl, (__a_4_axpy3)
	ex hl, de
	ld hl, (axpy3_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	pop hl
	add hl, de
	push hl
	ld hl, (__a_1_axpy3)
	ex hl, de
	ld hl, (axpy3_i)
	add hl, hl
	add hl, de
	pop de
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (axpy3_i)
	inc hl
	ld (axpy3_i), hl
	jp l_3
dot:
; 21 int dot(int *a, int *b, unsigned n) {
	ld (__a_3_dot), hl
; 22     unsigned i;
; 23     int acc;
; 24     acc = 0;
	ld hl, 0
	ld (dot_acc), hl
; 25     for (i = 0; i < n; i = i + 1) {
	ld (dot_i), hl
l_6:
	ld hl, (__a_3_dot)
	ex hl, de
	ld hl, (dot_i)
	call __o_sub_16
	jp nc, l_8
; 26         acc = acc + a[i] * b[i];
	ld hl, (__a_1_dot)
	ex hl, de
	ld hl, (dot_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de
	ld hl, (__a_2_dot)
	ex hl, de
	ld hl, (dot_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	pop de
	call __o_mul_i16
	ex hl, de
	ld hl, (dot_acc)
	add hl, de
	ld (dot_acc), hl
	ld hl, (dot_i)
	inc hl
	ld (dot_i), hl
	jp l_6
l_8:
; 27     }
; 28     return acc;
	ld hl, (dot_acc)
	ret
scale_copy:
; 31 void scale_copy(int *dst, int *src, unsigned n) {
	ld (__a_3_scale_copy), hl
; 32     unsigned i;
; 33     for (i = 0; i < n; i = i + 1) {
	ld hl, 0
	ld (scale_copy_i), hl
l_9:
	ld hl, (__a_3_scale_copy)
	ex hl, de
	ld hl, (scale_copy_i)
	call __o_sub_16
	ret nc
; 34         dst[i] = src[i] + src[i];
	ld hl, (__a_2_scale_copy)
	ex hl, de
	ld hl, (scale_copy_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de
	ld hl, (__a_2_scale_copy)
	ex hl, de
	ld hl, (scale_copy_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	pop de
	add hl, de
	push hl
	ld hl, (__a_1_scale_copy)
	ex hl, de
	ld hl, (scale_copy_i)
	add hl, hl
	add hl, de
	pop de
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (scale_copy_i)
	inc hl
	ld (scale_copy_i), hl
	jp l_9
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
__bss:
out:
	ds 16
a_0:
	ds 16
b_1:
	ds 16
c_2:
	ds 16
d1:
	ds 16
d2:
	ds 16
g_dot:
	ds 2
__static_stack:
	ds 16
__end:
__s___init equ __static_stack + 16
__s_main equ __static_stack + 12
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_axpy3 equ __static_stack + 0
__a_1_axpy3 equ __s_axpy3 + 2
__a_2_axpy3 equ __s_axpy3 + 4
__a_3_axpy3 equ __s_axpy3 + 6
__a_4_axpy3 equ __s_axpy3 + 8
__a_5_axpy3 equ __s_axpy3 + 10
__s_dot equ __static_stack + 0
__a_1_dot equ __s_dot + 4
__a_2_dot equ __s_dot + 6
__a_3_dot equ __s_dot + 8
__s_scale_copy equ __static_stack + 0
__a_1_scale_copy equ __s_scale_copy + 2
__a_2_scale_copy equ __s_scale_copy + 4
__a_3_scale_copy equ __s_scale_copy + 6
__s_seed equ __static_stack + 0
seed_i equ __s_seed + 0
axpy3_i equ __s_axpy3 + 0
dot_acc equ __s_dot + 2
dot_i equ __s_dot + 0
scale_copy_i equ __s_scale_copy + 0
__s___o_sub_16 equ __static_stack + 0
__s___o_mul_i16 equ __static_stack + 0
__s___o_minus_16 equ __static_stack + 0
__s___o_mul_u16 equ __static_stack + 0
    savebin "tests\features\43\c8080.bin", __begin, __bss - __begin
