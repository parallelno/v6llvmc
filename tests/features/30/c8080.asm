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
; 33 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 34     unsigned char src[4];
; 35     unsigned char dst[4];
; 36     src[0] = 10; src[1] = 20; src[2] = 30; src[3] = 40;
	ld a, 10
	ld (main_src), a
	ld a, 20
	ld (0FFFFh & ((main_src) + (1))), a
	ld a, 30
	ld (0FFFFh & ((main_src) + (2))), a
	ld a, 40
	ld (0FFFFh & ((main_src) + (3))), a
; 37     copy_pair(dst, src);
	ld hl, main_dst
	ld (__a_1_copy_pair), hl
	ld hl, main_src
	call copy_pair
; 38     use8(dst[0]);
	ld a, (main_dst)
	call use8
; 39     use8(dst[1]);
	ld a, (0FFFFh & ((main_dst) + (1)))
	call use8
; 40 
; 41     unsigned int val16 = 0x1234;
	ld hl, 4660
	ld (main_val16), hl
; 42     unsigned int r16 = load16_via_ptr(&val16);
	ld hl, main_val16
	call load16_via_ptr
	ld (main_r16), hl
; 43     use16(r16);
	call use16
; 44 
; 45     g_val = 0xABCD;
	ld hl, 43981
	ld (g_val), hl
; 46     unsigned int r_g = load16_global();
	call load16_global
	ld (main_r_g), hl
; 47     use16(r_g);
	call use16
; 48 
; 49     unsigned char s = sum_array(src, 4);
	ld hl, main_src
	ld (__a_1_sum_array), hl
	ld a, 4
	call sum_array
	ld (main_s), a
; 50     use8(s);
	call use8
; 51 
; 52     return 0;
	ld hl, 0
	ret
copy_pair:
; 7 void copy_pair(unsigned char *dst, const unsigned char *src) {
	ld (__a_2_copy_pair), hl
; 8     unsigned char a = src[0];
	ld a, (hl)
	ld (copy_pair_a), a
; 9     unsigned char b = src[1];
	inc hl
	ld a, (hl)
	ld (copy_pair_b), a
; 10     dst[0] = a;
	ld hl, (__a_1_copy_pair)
	ld a, (copy_pair_a)
	ld (hl), a
; 11     dst[1] = b;
	inc hl
	ld a, (copy_pair_b)
	ld (hl), a
	ret
use8:
; 4 void use8(unsigned char x) { /* stub */ }
	ld (__a_1_use8), a
	ret
load16_via_ptr:
; 14 unsigned int load16_via_ptr(unsigned int *p) {
	ld (__a_1_load16_via_ptr), hl
; 15     return *p;
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ret
use16:
; 5 void use16(unsigned int x) { /* stub */ }
	ld (__a_1_use16), hl
	ret
load16_global:
; 20 unsigned int load16_global() {
; 21     return g_val;
	ld hl, (g_val)
	ret
sum_array:
; 24 unsigned char sum_array(const unsigned char *arr, unsigned char n) {
	ld (__a_2_sum_array), a
; 25     unsigned char sum = 0;
	xor a
	ld (sum_array_sum), a
; 26     unsigned char i;
; 27     for (i = 0; i < n; i++) {
	ld (sum_array_i), a
l_0:
	ld hl, __a_2_sum_array
	cp (hl)
	jp nc, l_2
; 28         sum += arr[i];
	ld hl, (__a_1_sum_array)
	ex hl, de
	ld hl, (sum_array_i)
	ld h, 0
	add hl, de
	ld a, (sum_array_sum)
	add (hl)
	ld (sum_array_sum), a
	ld a, (sum_array_i)
	inc a
	ld (sum_array_i), a
	jp l_0
l_2:
; 29     }
; 30     return sum;
	ld a, (sum_array_sum)
	ret
__bss:
g_val:
	ds 2
__static_stack:
	ds 25
__end:
__s___init equ __static_stack + 25
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 15
__a_2_main equ __s_main + 17
main_src equ __s_main + 0
main_dst equ __s_main + 4
__s_copy_pair equ __static_stack + 0
__a_1_copy_pair equ __s_copy_pair + 2
__a_2_copy_pair equ __s_copy_pair + 4
__s_use8 equ __static_stack + 0
__a_1_use8 equ __s_use8 + 0
main_val16 equ __s_main + 8
main_r16 equ __s_main + 10
__s_load16_via_ptr equ __static_stack + 0
__a_1_load16_via_ptr equ __s_load16_via_ptr + 0
__s_use16 equ __static_stack + 0
__a_1_use16 equ __s_use16 + 0
main_r_g equ __s_main + 12
main_s equ __s_main + 14
__s_sum_array equ __static_stack + 0
__a_1_sum_array equ __s_sum_array + 2
__a_2_sum_array equ __s_sum_array + 4
copy_pair_a equ __s_copy_pair + 0
copy_pair_b equ __s_copy_pair + 1
__s_load16_global equ __static_stack + 0
sum_array_sum equ __s_sum_array + 0
sum_array_i equ __s_sum_array + 1
    savebin "tests\features\30\c8080.bin", __begin, __bss - __begin
