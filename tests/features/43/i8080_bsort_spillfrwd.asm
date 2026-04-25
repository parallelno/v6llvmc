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
; 28     asm{

        di

; 29         di
; 30     }
; 31     bsort(ARR, N);
	ld hl, arr
	ld (__a_1_bsort), hl
	ld a, 16
	call bsort
; 32     print_arr(ARR, N);
	ld hl, arr
	ld (__a_1_print_arr), hl
	ld a, 16
	call print_arr
; 33     asm{

        halt

; 34         halt
; 35     }
; 36     return 0;
	ld hl, 0
	ret
bsort:
; 7 void bsort(uint8_t *arr, uint8_t n) {
	ld (__a_2_bsort), a
; 8     for (uint8_t i = 0; i < n - 1; i++) {
	xor a
	ld (bsort_i), a
l_0:
	ld hl, (__a_2_bsort)
	ld h, 0
	dec hl
	ex hl, de
	ld hl, (bsort_i)
	ld h, 0
	call __o_sub_16
	ret nc
; 9         for (uint8_t j = 0; j < n - 1 - i; j++) {
	xor a
	ld (bsort_j), a
l_3:
	ld hl, (__a_2_bsort)
	ld h, 0
	dec hl
	ld a, (bsort_i)
	ld e, a
	ld d, 0
	call __o_sub_16
	ex hl, de
	ld hl, (bsort_j)
	ld h, 0
	call __o_sub_16
	jp nc, l_5
; 10             uint8_t a = arr[j];
	ld hl, (__a_1_bsort)
	ex hl, de
	ld hl, (bsort_j)
	ld h, 0
	add hl, de
	ld a, (hl)
	ld (bsort_a), a
; 11             uint8_t b = arr[j + 1];
	ld hl, (__a_1_bsort)
	ex hl, de
	ld hl, (bsort_j)
	ld h, 0
	inc hl
	add hl, de
	ld a, (hl)
	ld (bsort_b), a
; 12             if (a > b) {
	ld hl, bsort_a
	cp (hl)
	jp nc, l_6
; 13                 arr[j]     = b;
	ld hl, (__a_1_bsort)
	ex hl, de
	ld hl, (bsort_j)
	ld h, 0
	add hl, de
	ld (hl), a
; 14                 arr[j + 1] = a;
	ld hl, (__a_1_bsort)
	ex hl, de
	ld hl, (bsort_j)
	ld h, 0
	inc hl
	add hl, de
	ld a, (bsort_a)
	ld (hl), a
l_6:
	ld a, (bsort_j)
	inc a
	ld (bsort_j), a
	jp l_3
l_5:
	ld a, (bsort_i)
	inc a
	ld (bsort_i), a
	jp l_0
print_arr:
; 20 void print_arr(uint8_t *arr, uint8_t n) {
	ld (__a_2_print_arr), a
; 21     for (uint8_t i = 0; i < n; i++) {
	xor a
	ld (print_arr_i), a
l_8:
	ld hl, __a_2_print_arr
	cp (hl)
	ret nc
; 22         out(0xED, arr[i]);
	ld a, 237
	ld (__a_1_out), a
	ld hl, (__a_1_print_arr)
	ex hl, de
	ld hl, (print_arr_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	call out
	ld a, (print_arr_i)
	inc a
	ld (print_arr_i), a
	jp l_8
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
out:
; 20 void __global out(uint8_t port, uint8_t value) {
; 21     asm {

__a_2_out=0
__a_1_out=$+1
        out  (0), a

	ret
__bss:
arr:
	ds 16
__static_stack:
	ds 11
__end:
__s___init equ __static_stack + 11
__s_main equ __static_stack + 7
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_bsort equ __static_stack + 0
__a_1_bsort equ __s_bsort + 4
__a_2_bsort equ __s_bsort + 6
__s_print_arr equ __static_stack + 2
__a_1_print_arr equ __s_print_arr + 1
__a_2_print_arr equ __s_print_arr + 3
bsort_i equ __s_bsort + 0
bsort_j equ __s_bsort + 1
bsort_a equ __s_bsort + 2
bsort_b equ __s_bsort + 3
print_arr_i equ __s_print_arr + 0
__s_out equ __static_stack + 0
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\43\i8080_bsort_spillfrwd.bin", __begin, __bss - __begin
