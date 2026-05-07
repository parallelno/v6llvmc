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
; 28 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 29     case1_val_hl(0x1234);
	ld hl, 4660
	call case1_val_hl
; 30     case2a_val_de_hl_dead(0, 0x55AA);
	ld hl, 0
	ld (__a_1_case2a_val_de_hl_dead), hl
	ld hl, 21930
	call case2a_val_de_hl_dead
; 31     uint16_t r = case2b_val_de_hl_live(0x9988, 0x6677);
	ld hl, 39304
	ld (__a_1_case2b_val_de_hl_live), hl
	ld hl, 26231
	call case2b_val_de_hl_live
	ld (main_r), hl
; 32     case3a_val_bc_hl_dead(0, 0, 0xABCD);
	ld hl, 0
	ld (__a_1_case3a_val_bc_hl_dead), hl
	ld (__a_2_case3a_val_bc_hl_dead), hl
	ld hl, 43981
	call case3a_val_bc_hl_dead
; 33     return r;
	ld hl, (main_r)
	ret
case1_val_hl:
; 11 void case1_val_hl(uint16_t v) {
	ld (__a_1_case1_val_hl), hl
; 12     g_a = v;
	ld (g_a), hl
	ret
case2a_val_de_hl_dead:
; 15 void case2a_val_de_hl_dead(uint16_t a, uint16_t v) {
	ld (__a_2_case2a_val_de_hl_dead), hl
; 16     g_a = v;
	ld (g_a), hl
	ret
case2b_val_de_hl_live:
; 19 uint16_t case2b_val_de_hl_live(uint16_t hl_keep, uint16_t v) {
	ld (__a_2_case2b_val_de_hl_live), hl
; 20     g_a = v;
	ld (g_a), hl
; 21     return hl_keep;
	ld hl, (__a_1_case2b_val_de_hl_live)
	ret
case3a_val_bc_hl_dead:
; 24 void case3a_val_bc_hl_dead(uint16_t a, uint16_t b, uint16_t v) {
	ld (__a_3_case3a_val_bc_hl_dead), hl
; 25     g_a = v;
	ld (g_a), hl
	ret
__bss:
g_a:
	ds 2
__static_stack:
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
__s_case1_val_hl equ __static_stack + 0
__a_1_case1_val_hl equ __s_case1_val_hl + 0
__s_case2a_val_de_hl_dead equ __static_stack + 0
__a_1_case2a_val_de_hl_dead equ __s_case2a_val_de_hl_dead + 0
__a_2_case2a_val_de_hl_dead equ __s_case2a_val_de_hl_dead + 2
main_r equ __s_main + 0
__s_case2b_val_de_hl_live equ __static_stack + 0
__a_1_case2b_val_de_hl_live equ __s_case2b_val_de_hl_live + 0
__a_2_case2b_val_de_hl_live equ __s_case2b_val_de_hl_live + 2
__s_case3a_val_bc_hl_dead equ __static_stack + 0
__a_1_case3a_val_bc_hl_dead equ __s_case3a_val_bc_hl_dead + 0
__a_2_case3a_val_bc_hl_dead equ __s_case3a_val_bc_hl_dead + 2
__a_3_case3a_val_bc_hl_dead equ __s_case3a_val_bc_hl_dead + 4
    savebin "tests\features\56\c8080.bin", __begin, __bss - __begin
