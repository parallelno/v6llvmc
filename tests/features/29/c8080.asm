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
; 19 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 20     unsigned char buf_dst[4];
; 21     unsigned char buf_src1[4];
; 22     unsigned char buf_src2[4];
; 23 
; 24     buf_src1[0] = 10; buf_src1[1] = 20; buf_src1[2] = 30; buf_src1[3] = 40;
	ld a, 10
	ld (main_buf_src1), a
	ld a, 20
	ld (0FFFFh & ((main_buf_src1) + (1))), a
	ld a, 30
	ld (0FFFFh & ((main_buf_src1) + (2))), a
	ld a, 40
	ld (0FFFFh & ((main_buf_src1) + (3))), a
; 25     buf_src2[0] = 1;  buf_src2[1] = 2;  buf_src2[2] = 3;  buf_src2[3] = 4;
	ld a, 1
	ld (main_buf_src2), a
	ld a, 2
	ld (0FFFFh & ((main_buf_src2) + (1))), a
	ld a, 3
	ld (0FFFFh & ((main_buf_src2) + (2))), a
	ld a, 4
	ld (0FFFFh & ((main_buf_src2) + (3))), a
; 26 
; 27     interleaved_add(buf_dst, buf_src1, buf_src2, 4);
	ld hl, main_buf_dst
	ld (__a_1_interleaved_add), hl
	ld hl, main_buf_src1
	ld (__a_2_interleaved_add), hl
	ld hl, main_buf_src2
	ld (__a_3_interleaved_add), hl
	call interleaved_add
; 28 
; 29     return buf_dst[0];
	ld hl, (main_buf_dst)
	ld h, 0
	ret
interleaved_add:
; 10 void interleaved_add(unsigned char *dst, const unsigned char *src1,
	ld (__a_4_interleaved_add), a
; 11                      const unsigned char *src2, unsigned char n) {
; 12     unsigned char i;
; 13     for (i = 0; i < n; i++) {
	xor a
	ld (interleaved_add_i), a
l_0:
	ld hl, __a_4_interleaved_add
	cp (hl)
	jp nc, l_2
; 14         dst[i] = src1[i] + src2[i];
	ld hl, (__a_3_interleaved_add)
	ex hl, de
	ld hl, (interleaved_add_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	ld hl, (__a_2_interleaved_add)
	ex hl, de
	ld hl, (interleaved_add_i)
	ld h, 0
	add hl, de
	add (hl)
	ld hl, (__a_1_interleaved_add)
	ex hl, de
	ld hl, (interleaved_add_i)
	ld h, 0
	add hl, de
	ld (hl), a
	ld a, (interleaved_add_i)
	inc a
	ld (interleaved_add_i), a
	jp l_0
l_2:
; 15     }
; 16     use8(dst[0]);
	ld hl, (__a_1_interleaved_add)
	ld a, (hl)
use8:
; 6 void use8(unsigned char x) {
	ld (__a_1_use8), a
	ret
__bss:
__static_stack:
	ds 25
__end:
__s___init equ __static_stack + 25
__s_main equ __static_stack + 9
__a_1_main equ __s_main + 12
__a_2_main equ __s_main + 14
main_buf_src1 equ __s_main + 4
main_buf_src2 equ __s_main + 8
main_buf_dst equ __s_main + 0
__s_interleaved_add equ __static_stack + 1
__a_1_interleaved_add equ __s_interleaved_add + 1
__a_2_interleaved_add equ __s_interleaved_add + 3
__a_3_interleaved_add equ __s_interleaved_add + 5
__a_4_interleaved_add equ __s_interleaved_add + 7
interleaved_add_i equ __s_interleaved_add + 0
__s_use8 equ __static_stack + 0
__a_1_use8 equ __s_use8 + 0
    savebin "tests\features\29\c8080.bin", __begin, __bss - __begin
