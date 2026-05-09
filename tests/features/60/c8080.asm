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
; 61 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 62     (void)argc; (void)argv;
; 63     u8 *p = (u8 *)&g_buf;
	ld hl, g_buf
	ld (main_p), hl
; 64     store_hl(p);
	call store_hl
; 65     store_bc_a_dead(g_hl, g_de, p);
	ld hl, (g_hl)
	ld (__a_1_store_bc_a_dead), hl
	ld hl, (g_de)
	ld (__a_2_store_bc_a_dead), hl
	ld hl, (main_p)
	call store_bc_a_dead
; 66     store_de_a_dead(g_hl, p);
	ld hl, (g_hl)
	ld (__a_1_store_de_a_dead), hl
	ld hl, (main_p)
	call store_de_a_dead
; 67     store_de_a_live(g_hl, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_store_de_a_live), hl
	ld hl, (main_p)
	ld (__a_2_store_de_a_live), hl
	ld a, (g_a)
	call store_de_a_live
; 68     store_bc_hl_dead(g_hl, g_de, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_store_bc_hl_dead), hl
	ld hl, (g_de)
	ld (__a_2_store_bc_hl_dead), hl
	ld hl, (main_p)
	ld (__a_3_store_bc_hl_dead), hl
	ld a, (g_a)
	call store_bc_hl_dead
; 69     store_bc_de_dead(g_hl, g_de, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_store_bc_de_dead), hl
	ld hl, (g_de)
	ld (__a_2_store_bc_de_dead), hl
	ld hl, (main_p)
	ld (__a_3_store_bc_de_dead), hl
	ld a, (g_a)
	call store_bc_de_dead
; 70     store_bc_all_live(g_hl, g_de, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_store_bc_all_live), hl
	ld hl, (g_de)
	ld (__a_2_store_bc_all_live), hl
	ld hl, (main_p)
	ld (__a_3_store_bc_all_live), hl
	ld a, (g_a)
	call store_bc_all_live
; 71     return 0;
	ld hl, 0
	ret
store_hl:
; 13 void store_hl(u8 *p) {
	ld (__a_1_store_hl), hl
; 14     *p = 0x42;
	ld (hl), 66
	ret
store_bc_a_dead:
; 17 void store_bc_a_dead(unsigned hl_keep, unsigned de_keep, u8 *p) {
	ld (__a_3_store_bc_a_dead), hl
; 18     *p = 0x42;
	ld (hl), 66
; 19     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_bc_a_dead)
; 20     g_sink = (u8)de_keep;
	ld a, (__a_2_store_bc_a_dead)
	ld (g_sink), a
	ret
store_de_a_dead:
; 23 void store_de_a_dead(unsigned hl_keep, u8 *p) {
	ld (__a_2_store_de_a_dead), hl
; 24     *p = 0x42;
	ld (hl), 66
; 25     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_de_a_dead)
	ld (g_sink), a
	ret
store_de_a_live:
; 28 void store_de_a_live(unsigned hl_keep, u8 *p, u8 a_keep) {
	ld (__a_3_store_de_a_live), a
; 29     *p = 0x42;
	ld hl, (__a_2_store_de_a_live)
	ld (hl), 66
; 30     g_sink = a_keep;
; 31     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_de_a_live)
	ld (g_sink), a
	ret
store_bc_hl_dead:
; 34 void store_bc_hl_dead(unsigned hl_keep, unsigned de_keep, u8 *p, u8 a_keep) {
	ld (__a_4_store_bc_hl_dead), a
; 35     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_bc_hl_dead)
; 36     *p = 0x42;
	ld hl, (__a_3_store_bc_hl_dead)
	ld (hl), 66
; 37     g_sink = a_keep;
	ld a, (__a_4_store_bc_hl_dead)
; 38     g_sink = (u8)de_keep;
	ld a, (__a_2_store_bc_hl_dead)
	ld (g_sink), a
	ret
store_bc_de_dead:
; 41 void store_bc_de_dead(unsigned hl_keep, unsigned de_keep, u8 *p, u8 a_keep) {
	ld (__a_4_store_bc_de_dead), a
; 42     g_sink = (u8)de_keep;
	ld a, (__a_2_store_bc_de_dead)
; 43     *p = 0x42;
	ld hl, (__a_3_store_bc_de_dead)
	ld (hl), 66
; 44     g_sink = a_keep;
	ld a, (__a_4_store_bc_de_dead)
; 45     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_bc_de_dead)
	ld (g_sink), a
	ret
store_bc_all_live:
; 48 void store_bc_all_live(unsigned hl_keep, unsigned de_keep, u8 *p, u8 a_keep) {
	ld (__a_4_store_bc_all_live), a
; 49     *p = 0x42;
	ld hl, (__a_3_store_bc_all_live)
	ld (hl), 66
; 50     g_sink = a_keep;
; 51     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_bc_all_live)
; 52     g_sink = (u8)de_keep;
	ld a, (__a_2_store_bc_all_live)
	ld (g_sink), a
	ret
g_a:
	db 18
g_buf:
	db 0
g_hl:
	dw 4660
g_de:
	dw 22136
__bss:
g_sink:
	ds 1
__static_stack:
	ds 13
__end:
__s___init equ __static_stack + 13
__s_main equ __static_stack + 7
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_p equ __s_main + 0
__s_store_hl equ __static_stack + 0
__a_1_store_hl equ __s_store_hl + 0
__s_store_bc_a_dead equ __static_stack + 0
__a_1_store_bc_a_dead equ __s_store_bc_a_dead + 0
__a_2_store_bc_a_dead equ __s_store_bc_a_dead + 2
__a_3_store_bc_a_dead equ __s_store_bc_a_dead + 4
__s_store_de_a_dead equ __static_stack + 0
__a_1_store_de_a_dead equ __s_store_de_a_dead + 0
__a_2_store_de_a_dead equ __s_store_de_a_dead + 2
__s_store_de_a_live equ __static_stack + 0
__a_1_store_de_a_live equ __s_store_de_a_live + 0
__a_2_store_de_a_live equ __s_store_de_a_live + 2
__a_3_store_de_a_live equ __s_store_de_a_live + 4
__s_store_bc_hl_dead equ __static_stack + 0
__a_1_store_bc_hl_dead equ __s_store_bc_hl_dead + 0
__a_2_store_bc_hl_dead equ __s_store_bc_hl_dead + 2
__a_3_store_bc_hl_dead equ __s_store_bc_hl_dead + 4
__a_4_store_bc_hl_dead equ __s_store_bc_hl_dead + 6
__s_store_bc_de_dead equ __static_stack + 0
__a_1_store_bc_de_dead equ __s_store_bc_de_dead + 0
__a_2_store_bc_de_dead equ __s_store_bc_de_dead + 2
__a_3_store_bc_de_dead equ __s_store_bc_de_dead + 4
__a_4_store_bc_de_dead equ __s_store_bc_de_dead + 6
__s_store_bc_all_live equ __static_stack + 0
__a_1_store_bc_all_live equ __s_store_bc_all_live + 0
__a_2_store_bc_all_live equ __s_store_bc_all_live + 2
__a_3_store_bc_all_live equ __s_store_bc_all_live + 4
__a_4_store_bc_all_live equ __s_store_bc_all_live + 6
    savebin "tests\features\60\c8080.bin", __begin, __bss - __begin
