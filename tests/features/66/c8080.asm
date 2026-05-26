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
; 34     fillscreen();
	call fillscreen
; 35     fillscreen_nonzero();
	call fillscreen_nonzero
; 36     return 0;
	ld hl, 0
	ret
fillscreen:
; 7 void fillscreen(void) {
; 8     unsigned char *src = (unsigned char *)0xF800;
	ld hl, 63488
	ld (fillscreen_src), hl
; 9     unsigned char *dst = (unsigned char *)0x7802;
	ld hl, 30722
	ld (fillscreen_dst), hl
; 10     unsigned char y, x;
; 11     for (y = 0; y < 25; y++) {
	xor a
	ld (fillscreen_y), a
l_0:
	cp 25
	ret nc
; 12         for (x = 0; x < 64; x++) {
	xor a
	ld (fillscreen_x), a
l_3:
	cp 64
	jp nc, l_5
; 13             unsigned char b = *src++;
	ld hl, (fillscreen_src)
	inc hl
	ld (fillscreen_src), hl
	dec hl
	ld a, (hl)
	ld (fillscreen_b), a
; 14             *dst++ = (b & 4) ? 0x4F : 0x00;
	ld hl, (fillscreen_dst)
	inc hl
	ld (fillscreen_dst), hl
	dec hl
	and 4
	jp z, l_6
	ld a, 79
	jp l_7
l_6:
	xor a
l_7:
	ld (hl), a
	ld a, (fillscreen_x)
	inc a
	ld (fillscreen_x), a
	jp l_3
l_5:
; 15         }
; 16         dst += 15;
	ld hl, (fillscreen_dst)
	ld de, 15
	add hl, de
	ld (fillscreen_dst), hl
	ld a, (fillscreen_y)
	inc a
	ld (fillscreen_y), a
	jp l_0
fillscreen_nonzero:
; 20 void fillscreen_nonzero(void) {
; 21     unsigned char *src = (unsigned char *)0xF800;
	ld hl, 63488
	ld (fillscreen_nonzero_src), hl
; 22     unsigned char *dst = (unsigned char *)0x7802;
	ld hl, 30722
	ld (fillscreen_nonzero_dst), hl
; 23     unsigned char y, x;
; 24     for (y = 0; y < 25; y++) {
	xor a
	ld (fillscreen_nonzero_y), a
l_8:
	cp 25
	ret nc
; 25         for (x = 0; x < 64; x++) {
	xor a
	ld (fillscreen_nonzero_x), a
l_11:
	cp 64
	jp nc, l_13
; 26             unsigned char b = *src++;
	ld hl, (fillscreen_nonzero_src)
	inc hl
	ld (fillscreen_nonzero_src), hl
	dec hl
	ld a, (hl)
	ld (fillscreen_nonzero_b), a
; 27             *dst++ = (b & 4) ? 0xFE : 0x01;
	ld hl, (fillscreen_nonzero_dst)
	inc hl
	ld (fillscreen_nonzero_dst), hl
	dec hl
	and 4
	jp z, l_14
	ld a, 254
	jp l_15
l_14:
	ld a, 1
l_15:
	ld (hl), a
	ld a, (fillscreen_nonzero_x)
	inc a
	ld (fillscreen_nonzero_x), a
	jp l_11
l_13:
; 28         }
; 29         dst += 15;
	ld hl, (fillscreen_nonzero_dst)
	ld de, 15
	add hl, de
	ld (fillscreen_nonzero_dst), hl
	ld a, (fillscreen_nonzero_y)
	inc a
	ld (fillscreen_nonzero_y), a
	jp l_8
__bss:
__static_stack:
	ds 11
__end:
__s___init equ __static_stack + 11
__s_main equ __static_stack + 7
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_fillscreen equ __static_stack + 0
fillscreen_src equ __s_fillscreen + 0
fillscreen_dst equ __s_fillscreen + 2
fillscreen_y equ __s_fillscreen + 4
fillscreen_x equ __s_fillscreen + 5
fillscreen_b equ __s_fillscreen + 6
__s_fillscreen_nonzero equ __static_stack + 0
fillscreen_nonzero_src equ __s_fillscreen_nonzero + 0
fillscreen_nonzero_dst equ __s_fillscreen_nonzero + 2
fillscreen_nonzero_y equ __s_fillscreen_nonzero + 4
fillscreen_nonzero_x equ __s_fillscreen_nonzero + 5
fillscreen_nonzero_b equ __s_fillscreen_nonzero + 6
    savebin "tests\features\66\c8080.bin", __begin, __bss - __begin
