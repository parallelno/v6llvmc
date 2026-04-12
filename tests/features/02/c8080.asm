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
; 21 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 22     countdown(5);
	ld a, 5
	call countdown
; 23     return count_down(10);
	ld a, 10
	call count_down
	ld l, a
	ld h, 0
	ret
countdown:
; 6 void countdown(unsigned char n) {
	ld (__a_1_countdown), a
; 7     while (n != 0) {
l_0:
	or a
	ret z
; 8         output_port = n;
	ld (output_port), a
; 9         n--;
	ld a, (__a_1_countdown)
	dec a
	ld (__a_1_countdown), a
	jp l_0
count_down:
; 14 unsigned char count_down(unsigned char n) {
	ld (__a_1_count_down), a
; 15     while (n != 0) {
l_2:
	or a
	ret z
; 16         n--;
	dec a
	ld (__a_1_count_down), a
	jp l_2
__bss:
output_port:
	ds 1
__static_stack:
	ds 5
__end:
__s___init equ __static_stack + 5
__s_main equ __static_stack + 1
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_countdown equ __static_stack + 0
__a_1_countdown equ __s_countdown + 0
__s_count_down equ __static_stack + 0
__a_1_count_down equ __s_count_down + 0
    savebin "tests\features\02\c8080.bin", __begin, __bss - __begin
