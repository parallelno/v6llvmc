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
; 29 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 30     unsigned char *p = (unsigned char *)mem;
	ld hl, mem
	ld (main_p), hl
; 31     read_offset1(p);
	call read_offset1
; 32     read_offset2(p);
	ld hl, (main_p)
	call read_offset2
; 33     read_offset3(p);
	ld hl, (main_p)
	call read_offset3
; 34     read_offset4(p);
	ld hl, (main_p)
	call read_offset4
; 35     sum_adjacent(p);
	ld hl, (main_p)
	call sum_adjacent
; 36     sum_three(p);
	ld hl, (main_p)
	call sum_three
; 37     return 0;
	ld hl, 0
	ret
read_offset1:
; 5 unsigned char read_offset1(unsigned char *p) {
	ld (__a_1_read_offset1), hl
; 6     return *(p + 1);
	inc hl
	ld a, (hl)
	ret
read_offset2:
; 9 unsigned char read_offset2(unsigned char *p) {
	ld (__a_1_read_offset2), hl
; 10     return *(p + 2);
	inc hl
	inc hl
	ld a, (hl)
	ret
read_offset3:
; 13 unsigned char read_offset3(unsigned char *p) {
	ld (__a_1_read_offset3), hl
; 14     return *(p + 3);
	inc hl
	inc hl
	inc hl
	ld a, (hl)
	ret
read_offset4:
; 17 unsigned char read_offset4(unsigned char *p) {
	ld (__a_1_read_offset4), hl
; 18     return *(p + 4);
	ld de, 4
	add hl, de
	ld a, (hl)
	ret
sum_adjacent:
; 21 unsigned int sum_adjacent(unsigned char *p) {
	ld (__a_1_sum_adjacent), hl
; 22     return (unsigned int)p[0] + p[1];
	ld e, (hl)
	ld d, 0
	inc hl
	ld l, (hl)
	ld h, 0
	add hl, de
	ret
sum_three:
; 25 unsigned int sum_three(unsigned char *p) {
	ld (__a_1_sum_three), hl
; 26     return (unsigned int)p[0] + p[1] + p[2];
	ld e, (hl)
	ld d, 0
	inc hl
	ld l, (hl)
	ld h, 0
	add hl, de
	ex hl, de
	ld hl, (__a_1_sum_three)
	inc hl
	inc hl
	ld l, (hl)
	ld h, 0
	add hl, de
	ret
__bss:
mem:
	ds 16
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_p equ __s_main + 0
__s_read_offset1 equ __static_stack + 0
__a_1_read_offset1 equ __s_read_offset1 + 0
__s_read_offset2 equ __static_stack + 0
__a_1_read_offset2 equ __s_read_offset2 + 0
__s_read_offset3 equ __static_stack + 0
__a_1_read_offset3 equ __s_read_offset3 + 0
__s_read_offset4 equ __static_stack + 0
__a_1_read_offset4 equ __s_read_offset4 + 0
__s_sum_adjacent equ __static_stack + 0
__a_1_sum_adjacent equ __s_sum_adjacent + 0
__s_sum_three equ __static_stack + 0
__a_1_sum_three equ __s_sum_three + 0
    savebin "tests\features\04\c8080.bin", __begin, __bss - __begin
