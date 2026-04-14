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
; 20 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 21     fill_array(42);
	ld a, 42
	call fill_array
; 22     copy_array();
	call copy_array
; 23     return array2[0] + array2[99];
	ld hl, (array2)
	ld h, 0
	ex hl, de
	ld hl, (0FFFFh & ((array2) + (99)))
	ld h, 0
	add hl, de
	ret
fill_array:
; 8 void fill_array(unsigned char start_val) {
	ld (__a_1_fill_array), a
; 9     unsigned char i;
; 10     for (i = 0; i < LEN; i++)
	xor a
	ld (fill_array_i), a
l_0:
	cp 100
	ret nc
; 11         array1[i] = start_val + i;
	ld hl, __a_1_fill_array
	add (hl)
	ld de, array1
	ld hl, (fill_array_i)
	ld h, 0
	add hl, de
	ld (hl), a
	ld a, (fill_array_i)
	inc a
	ld (fill_array_i), a
	jp l_0
copy_array:
; 14 void copy_array(void) {
; 15     unsigned char i;
; 16     for (i = 0; i < LEN; i++)
	xor a
	ld (copy_array_i), a
l_3:
	cp 100
	ret nc
; 17         array2[i] = array1[i];
	ld de, array1
	ld hl, (copy_array_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	ld de, array2
	ld hl, (copy_array_i)
	ld h, 0
	add hl, de
	ld (hl), a
	ld a, (copy_array_i)
	inc a
	ld (copy_array_i), a
	jp l_3
__bss:
array1:
	ds 100
array2:
	ds 100
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_fill_array equ __static_stack + 0
__a_1_fill_array equ __s_fill_array + 1
fill_array_i equ __s_fill_array + 0
__s_copy_array equ __static_stack + 0
copy_array_i equ __s_copy_array + 0
    savebin "tests\features\23\c8080.bin", __begin, __bss - __begin
