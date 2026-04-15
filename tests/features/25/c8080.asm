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
; 28     return sumarray() + singlesum();
	call sumarray
	push hl
	call singlesum
	pop de
	add hl, de
	ret
sumarray:
; 7 int sumarray() {
; 8     int sum;
; 9     int i;
; 10     sum = 0;
	ld hl, 0
	ld (sumarray_sum), hl
; 11     for (i = 0; i < 100; ++i)
	ld (sumarray_i), hl
l_0:
	ld de, 100
	call __o_sub_16
	jp p, l_2
; 12         sum += arr1[i] + arr2[i];
	ld de, arr1
	ld hl, (sumarray_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	push de
	ld de, arr2
	ld hl, (sumarray_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	pop de
	add hl, de
	ex hl, de
	ld hl, (sumarray_sum)
	add hl, de
	ld (sumarray_sum), hl
	ld hl, (sumarray_i)
	inc hl
	ld (sumarray_i), hl
	jp l_0
l_2:
; 13     return sum;
	ld hl, (sumarray_sum)
	ret
singlesum:
; 18 int singlesum() {
; 19     int total;
; 20     int i;
; 21     total = 0;
	ld hl, 0
	ld (singlesum_total), hl
; 22     for (i = 0; i < 50; ++i)
	ld (singlesum_i), hl
l_3:
	ld de, 50
	call __o_sub_16
	jp p, l_5
; 23         total += data[i];
	ld de, data
	ld hl, (singlesum_i)
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld hl, (singlesum_total)
	add hl, de
	ld (singlesum_total), hl
	ld hl, (singlesum_i)
	inc hl
	ld (singlesum_i), hl
	jp l_3
l_5:
; 24     return total;
	ld hl, (singlesum_total)
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
__bss:
arr1:
	ds 200
arr2:
	ds 200
data:
	ds 100
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 4
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_sumarray equ __static_stack + 0
sumarray_sum equ __s_sumarray + 0
sumarray_i equ __s_sumarray + 2
__s_singlesum equ __static_stack + 0
singlesum_total equ __s_singlesum + 0
singlesum_i equ __s_singlesum + 2
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\25\c8080.bin", __begin, __bss - __begin
