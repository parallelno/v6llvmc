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
; 43 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 44     buf[0] = 0;
	ld hl, 0
	ld (buf), hl
; 45     buf[1] = 0;
	ld (0FFFFh & ((buf) + (2))), hl
; 46     buf[2] = 0;
	ld (0FFFFh & ((buf) + (4))), hl
; 47 
; 48     row3_de_hl(0xAA55, &buf[0]);
	ld hl, 43605
	ld (__a_1_row3_de_hl), hl
	ld hl, buf
	call row3_de_hl
; 49     g_r = row2_hl_reused(&buf[1], 0x1234);
	ld hl, 0FFFFh & ((buf) + (2))
	ld (__a_1_row2_hl_reused), hl
	ld hl, 4660
	call row2_hl_reused
	ld (g_r), hl
; 50     g_r = row5_bc_hl_a_live(0xCAFE, 0x99, &buf[2]);
	ld hl, 51966
	ld (__a_1_row5_bc_hl_a_live), hl
	ld a, 153
	ld (__a_2_row5_bc_hl_a_live), a
	ld hl, 0FFFFh & ((buf) + (4))
	call row5_bc_hl_a_live
	ld l, a
	ld h, 0
	ld (g_r), hl
; 51     row6_bc_bc(0x1111, 0x2222, &buf[0]);
	ld hl, 4369
	ld (__a_1_row6_bc_bc), hl
	ld hl, 8738
	ld (__a_2_row6_bc_bc), hl
	ld hl, buf
	call row6_bc_bc
; 52     g_r = row4_de_de(0xBEEF, &buf[1]);
	ld hl, 48879
	ld (__a_1_row4_de_de), hl
	ld hl, 0FFFFh & ((buf) + (2))
	call row4_de_de
	ld (g_r), hl
; 53 
; 54     return 0;
	ld hl, 0
	ret
row3_de_hl:
; 15 void row3_de_hl(uint16_t v, uint16_t *p) {
	ld (__a_2_row3_de_hl), hl
; 16     *p = v;
	ld hl, (__a_1_row3_de_hl)
	ex hl, de
	ld hl, (__a_2_row3_de_hl)
	ld (hl), e
	inc hl
	ld (hl), d
; 17     g_r = (uint16_t)p;
	ld hl, (__a_2_row3_de_hl)
	ld (g_r), hl
	ret
row2_hl_reused:
; 20 uint16_t row2_hl_reused(uint16_t *p, uint16_t v) {
	ld (__a_2_row2_hl_reused), hl
; 21     p[0] = v;
	ex hl, de
	ld hl, (__a_1_row2_hl_reused)
	ld (hl), e
	inc hl
	ld (hl), d
; 22     return p[0];
	ld hl, (__a_1_row2_hl_reused)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ret
row5_bc_hl_a_live:
; 25 uint8_t row5_bc_hl_a_live(uint16_t v, uint8_t a_keep, uint16_t *p) {
	ld (__a_3_row5_bc_hl_a_live), hl
; 26     *p = v;
	ld hl, (__a_1_row5_bc_hl_a_live)
	ex hl, de
	ld hl, (__a_3_row5_bc_hl_a_live)
	ld (hl), e
	inc hl
	ld (hl), d
; 27     return a_keep ^ 0x42;
	ld a, (__a_2_row5_bc_hl_a_live)
	xor 66
	ret
row6_bc_bc:
; 30 void row6_bc_bc(uint16_t a, uint16_t b, uint16_t *p) {
	ld (__a_3_row6_bc_bc), hl
; 31     *p = (uint16_t)p;
	ex hl, de
	ld hl, (__a_3_row6_bc_bc)
	ld (hl), e
	inc hl
	ld (hl), d
; 32     g_a = a;
	ld hl, (__a_1_row6_bc_bc)
	ld (g_a), hl
; 33     g_b = b;
	ld hl, (__a_2_row6_bc_bc)
	ld (g_b), hl
	ret
row4_de_de:
; 36 uint16_t row4_de_de(uint16_t hl_keep, uint16_t *p) {
	ld (__a_2_row4_de_de), hl
; 37     *p = (uint16_t)p;
	ex hl, de
	ld hl, (__a_2_row4_de_de)
	ld (hl), e
	inc hl
	ld (hl), d
; 38     return hl_keep;
	ld hl, (__a_1_row4_de_de)
	ret
__bss:
g_a:
	ds 2
g_b:
	ds 2
g_r:
	ds 2
buf:
	ds 6
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_row3_de_hl equ __static_stack + 0
__a_1_row3_de_hl equ __s_row3_de_hl + 0
__a_2_row3_de_hl equ __s_row3_de_hl + 2
__s_row2_hl_reused equ __static_stack + 0
__a_1_row2_hl_reused equ __s_row2_hl_reused + 0
__a_2_row2_hl_reused equ __s_row2_hl_reused + 2
__s_row5_bc_hl_a_live equ __static_stack + 0
__a_1_row5_bc_hl_a_live equ __s_row5_bc_hl_a_live + 0
__a_2_row5_bc_hl_a_live equ __s_row5_bc_hl_a_live + 2
__a_3_row5_bc_hl_a_live equ __s_row5_bc_hl_a_live + 3
__s_row6_bc_bc equ __static_stack + 0
__a_1_row6_bc_bc equ __s_row6_bc_bc + 0
__a_2_row6_bc_bc equ __s_row6_bc_bc + 2
__a_3_row6_bc_bc equ __s_row6_bc_bc + 4
__s_row4_de_de equ __static_stack + 0
__a_1_row4_de_de equ __s_row4_de_de + 0
__a_2_row4_de_de equ __s_row4_de_de + 2
    savebin "tests\features\54\c8080.bin", __begin, __bss - __begin
