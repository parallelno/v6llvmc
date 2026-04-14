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
; 34 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 35     unsigned char buf_dst[4];
; 36     unsigned char buf_src[4];
; 37     volatile unsigned char r;
; 38 
; 39     buf_dst[0] = 0; buf_dst[1] = 0; buf_dst[2] = 0; buf_dst[3] = 0;
	xor a
	ld (main_buf_dst), a
	ld (0FFFFh & ((main_buf_dst) + (1))), a
	ld (0FFFFh & ((main_buf_dst) + (2))), a
	ld (0FFFFh & ((main_buf_dst) + (3))), a
; 40     buf_src[0] = 10; buf_src[1] = 20; buf_src[2] = 30; buf_src[3] = 40;
	ld a, 10
	ld (main_buf_src), a
	ld a, 20
	ld (0FFFFh & ((main_buf_src) + (1))), a
	ld a, 30
	ld (0FFFFh & ((main_buf_src) + (2))), a
	ld a, 40
	ld (0FFFFh & ((main_buf_src) + (3))), a
; 41 
; 42     multi_ptr_copy(buf_dst, buf_src, 4);
	ld hl, main_buf_dst
	ld (__a_1_multi_ptr_copy), hl
	ld hl, main_buf_src
	ld (__a_2_multi_ptr_copy), hl
	ld a, 4
	call multi_ptr_copy
; 43     r = buf_dst[0];
	ld a, (main_buf_dst)
	ld (main_r), a
; 44 
; 45     r = multi_live(1, 2, 3);
	ld a, 1
	ld (__a_1_multi_live), a
	ld a, 2
	ld (__a_2_multi_live), a
	ld a, 3
	call multi_live
	ld (main_r), a
; 46     r = nested_calls(5, 6);
	ld a, 5
	ld (__a_1_nested_calls), a
	ld a, 6
	call nested_calls
	ld (main_r), a
; 47 
; 48     return r;
	ld hl, (main_r)
	ld h, 0
	ret
multi_ptr_copy:
; 12 void multi_ptr_copy(unsigned char *dst, unsigned char *src, unsigned char n) {
	ld (__a_3_multi_ptr_copy), a
; 13     unsigned char i;
; 14     for (i = 0; i < n; i++) {
	xor a
	ld (multi_ptr_copy_i), a
l_0:
	ld hl, __a_3_multi_ptr_copy
	cp (hl)
	ret nc
; 15         dst[i] = src[i] + 1;
	ld hl, (__a_2_multi_ptr_copy)
	ex hl, de
	ld hl, (multi_ptr_copy_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	inc a
	ld hl, (__a_1_multi_ptr_copy)
	ex hl, de
	ld hl, (multi_ptr_copy_i)
	ld h, 0
	add hl, de
	ld (hl), a
	ld a, (multi_ptr_copy_i)
	inc a
	ld (multi_ptr_copy_i), a
	jp l_0
multi_live:
; 19 unsigned char multi_live(unsigned char a, unsigned char b, unsigned char c) {
	ld (__a_3_multi_live), a
; 20     unsigned char x = a + 1;
	ld a, (__a_1_multi_live)
	inc a
	ld (multi_live_x), a
; 21     unsigned char y = b + 2;
	ld a, (__a_2_multi_live)
	add 2
	ld (multi_live_y), a
; 22     use8(c);
	ld a, (__a_3_multi_live)
	call use8
; 23     return x + y;
	ld hl, multi_live_x
	ld a, (multi_live_y)
	add (hl)
	ret
nested_calls:
; 26 unsigned char nested_calls(unsigned char a, unsigned char b) {
	ld (__a_2_nested_calls), a
; 27     unsigned char x = get8();
	call get8
	ld (nested_calls_x), a
; 28     unsigned char y = a + x;
	ld hl, __a_1_nested_calls
	add (hl)
	ld (nested_calls_y), a
; 29     use8(b);
	ld a, (__a_2_nested_calls)
	call use8
; 30     unsigned char z = get8();
	call get8
	ld (nested_calls_z), a
; 31     return y + z;
	ld hl, nested_calls_y
	add (hl)
	ret
use8:
; 4 void use8(unsigned char x) {
	ld (__a_1_use8), a
	ret
get8:
; 8 unsigned char get8(void) {
; 9     return 42;
	ld a, 42
	ret
__bss:
__static_stack:
	ds 19
__end:
__s___init equ __static_stack + 19
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 9
__a_2_main equ __s_main + 11
main_buf_dst equ __s_main + 0
main_buf_src equ __s_main + 4
__s_multi_ptr_copy equ __static_stack + 0
__a_1_multi_ptr_copy equ __s_multi_ptr_copy + 1
__a_2_multi_ptr_copy equ __s_multi_ptr_copy + 3
__a_3_multi_ptr_copy equ __s_multi_ptr_copy + 5
main_r equ __s_main + 8
__s_multi_live equ __static_stack + 1
__a_1_multi_live equ __s_multi_live + 2
__a_2_multi_live equ __s_multi_live + 3
__a_3_multi_live equ __s_multi_live + 4
__s_nested_calls equ __static_stack + 1
__a_1_nested_calls equ __s_nested_calls + 3
__a_2_nested_calls equ __s_nested_calls + 4
multi_ptr_copy_i equ __s_multi_ptr_copy + 0
multi_live_x equ __s_multi_live + 0
multi_live_y equ __s_multi_live + 1
__s_use8 equ __static_stack + 0
__a_1_use8 equ __s_use8 + 0
nested_calls_x equ __s_nested_calls + 0
nested_calls_y equ __s_nested_calls + 1
nested_calls_z equ __s_nested_calls + 2
__s_get8 equ __static_stack + 0
    savebin "tests\features\20\c8080.bin", __begin, __bss - __begin
