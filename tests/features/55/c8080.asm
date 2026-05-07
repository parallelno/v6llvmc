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
; 32 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 33     g_a = 0x1234;
	ld hl, 4660
	ld (g_a), hl
; 34     g_b = 0x5678;
	ld hl, 22136
	ld (g_b), hl
; 35     g_c = 0x0001;
	ld hl, 1
	ld (g_c), hl
; 36 
; 37     g_r = case1_dst_hl();
	call case1_dst_hl
	ld (g_r), hl
; 38     g_r = case2_dst_de(0x0100);
	ld hl, 256
	call case2_dst_de
	ld (g_r), hl
; 39     g_r = case3_dst_bc();
	call case3_dst_bc
	ld (g_r), hl
; 40 
; 41     return 0;
	ld hl, 0
	ret
case1_dst_hl:
; 15 uint16_t case1_dst_hl(void) {
; 16     return g_a;
	ld hl, (g_a)
	ret
case2_dst_de:
; 19 uint16_t case2_dst_de(uint16_t hl_keep) {
	ld (__a_1_case2_dst_de), hl
; 20     return hl_keep + g_a;
	ex hl, de
	ld hl, (g_a)
	add hl, de
	ret
case3_dst_bc:
; 27 uint16_t case3_dst_bc(void) {
; 28     return add3(g_a, g_b, g_c);
	ld hl, (g_a)
	ld (__a_1_add3), hl
	ld hl, (g_b)
	ld (__a_2_add3), hl
	ld hl, (g_c)
add3:
; 23 uint16_t add3(uint16_t a, uint16_t b, uint16_t c) {
	ld (__a_3_add3), hl
; 24     return a + b + c;
	ld hl, (__a_1_add3)
	ex hl, de
	ld hl, (__a_2_add3)
	add hl, de
	ex hl, de
	ld hl, (__a_3_add3)
	add hl, de
	ret
__bss:
g_a:
	ds 2
g_b:
	ds 2
g_c:
	ds 2
g_r:
	ds 2
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_case2_dst_de equ __static_stack + 0
__a_1_case2_dst_de equ __s_case2_dst_de + 0
__s_case1_dst_hl equ __static_stack + 0
__s_case3_dst_bc equ __static_stack + 6
__s_add3 equ __static_stack + 0
__a_1_add3 equ __s_add3 + 0
__a_2_add3 equ __s_add3 + 2
__a_3_add3 equ __s_add3 + 4
    savebin "tests\features\55\c8080.bin", __begin, __bss - __begin
