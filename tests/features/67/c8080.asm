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
; 40 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 41     uint8_t arr[64];
; 42     uint8_t k;
; 43     for (k = 0; k < 64; k++) arr[k] = k;
	xor a
	ld (main_k), a
l_0:
	cp 64
	jp nc, l_2
	ld de, main_arr
	ld hl, (main_k)
	ld h, 0
	add hl, de
	ld (hl), a
	inc a
	ld (main_k), a
	jp l_0
l_2:
; 44     return (int)(iter_xor_mix(7) + iter_xor_next(7) + weighted_sum(arr)) & 0xFF;
	ld a, 7
	call iter_xor_mix
	push hl
	ld a, 7
	call iter_xor_next
	pop de
	add hl, de
	push hl
	ld hl, main_arr
	call weighted_sum
	pop de
	add hl, de
	ld de, 255
	jp __o_and_16
iter_xor_mix:
; 11 uint16_t iter_xor_mix(uint8_t seed) {
	ld (__a_1_iter_xor_mix), a
; 12     uint16_t acc = seed;
	ld hl, (__a_1_iter_xor_mix)
	ld h, 0
	ld (iter_xor_mix_acc), hl
; 13     uint8_t i;  // c8080 uses i8 counter naturally
; 14     for (i = 0; i < 64; i++) {
	xor a
	ld (iter_xor_mix_i), a
l_3:
	cp 64
	jp nc, l_5
; 15         acc += acc ^ (uint16_t)i;
	ex hl, de
	ld hl, (iter_xor_mix_i)
	ld h, 0
	call __o_xor_16
	ex hl, de
	ld hl, (iter_xor_mix_acc)
	add hl, de
	ld (iter_xor_mix_acc), hl
	ld a, (iter_xor_mix_i)
	inc a
	ld (iter_xor_mix_i), a
	jp l_3
l_5:
; 16     }
; 17     return acc;
	ld hl, (iter_xor_mix_acc)
	ret
iter_xor_next:
; 21 uint16_t iter_xor_next(uint8_t seed) {
	ld (__a_1_iter_xor_next), a
; 22     uint16_t acc = seed;
	ld hl, (__a_1_iter_xor_next)
	ld h, 0
	ld (iter_xor_next_acc), hl
; 23     uint8_t i;
; 24     for (i = 0; i < 64; i++) {
	xor a
	ld (iter_xor_next_i), a
l_6:
	cp 64
	jp nc, l_8
; 25         acc += acc ^ (uint16_t)(i + 1);
	ex hl, de
	ld hl, (iter_xor_next_i)
	ld h, 0
	inc hl
	call __o_xor_16
	ex hl, de
	ld hl, (iter_xor_next_acc)
	add hl, de
	ld (iter_xor_next_acc), hl
	ld a, (iter_xor_next_i)
	inc a
	ld (iter_xor_next_i), a
	jp l_6
l_8:
; 26     }
; 27     return acc;
	ld hl, (iter_xor_next_acc)
	ret
weighted_sum:
; 31 uint16_t weighted_sum(uint8_t *arr) {
	ld (__a_1_weighted_sum), hl
; 32     uint16_t s = 0;
	ld hl, 0
	ld (weighted_sum_s), hl
; 33     uint8_t i;
; 34     for (i = 0; i < 64; i++) {
	xor a
	ld (weighted_sum_i), a
l_9:
	cp 64
	jp nc, l_11
; 35         s += (uint16_t)arr[i] + i;
	ld hl, (__a_1_weighted_sum)
	ex hl, de
	ld hl, (weighted_sum_i)
	ld h, 0
	add hl, de
	ld e, (hl)
	ld d, 0
	ld hl, (weighted_sum_i)
	ld h, 0
	add hl, de
	ex hl, de
	ld hl, (weighted_sum_s)
	add hl, de
	ld (weighted_sum_s), hl
	inc a
	ld (weighted_sum_i), a
	jp l_9
l_11:
; 36     }
; 37     return s;
	ld hl, (weighted_sum_s)
	ret
__o_and_16:
; 280 void __o_and_16() {
; 281     asm {

        ld   a, h
        and  d
        ld   h, a
        ld   a, l
        and  e
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
__bss:
__static_stack:
	ds 74
__end:
__s___init equ __static_stack + 74
__s_main equ __static_stack + 5
__a_1_main equ __s_main + 65
__a_2_main equ __s_main + 67
main_k equ __s_main + 64
main_arr equ __s_main + 0
__s_iter_xor_mix equ __static_stack + 0
__a_1_iter_xor_mix equ __s_iter_xor_mix + 3
__s_iter_xor_next equ __static_stack + 0
__a_1_iter_xor_next equ __s_iter_xor_next + 3
__s_weighted_sum equ __static_stack + 0
__a_1_weighted_sum equ __s_weighted_sum + 3
iter_xor_mix_acc equ __s_iter_xor_mix + 0
iter_xor_mix_i equ __s_iter_xor_mix + 2
iter_xor_next_acc equ __s_iter_xor_next + 0
iter_xor_next_i equ __s_iter_xor_next + 2
weighted_sum_s equ __s_weighted_sum + 0
weighted_sum_i equ __s_weighted_sum + 2
__s___o_and_16 equ __static_stack + 0
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\67\c8080.bin", __begin, __bss - __begin
