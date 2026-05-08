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
; 50 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 51     (void)argc; (void)argv;
; 52     u8 *p = (u8 *)&g_buf;
	ld hl, g_buf
	ld (main_p), hl
; 53     store_use_b(g_hl, p, g_a, g_v);
	ld hl, (g_hl)
	ld (__a_1_store_use_b), hl
	ld hl, (main_p)
	ld (__a_2_store_use_b), hl
	ld a, (g_a)
	ld (__a_3_store_use_b), a
	ld a, (g_v)
	call store_use_b
; 54     store_use_c(g_hl, p, g_a, g_v);
	ld hl, (g_hl)
	ld (__a_1_store_use_c), hl
	ld hl, (main_p)
	ld (__a_2_store_use_c), hl
	ld a, (g_a)
	ld (__a_3_store_use_c), a
	ld a, (g_v)
	call store_use_c
; 55     store_use_h(g_hl, p, g_a, g_v);
	ld hl, (g_hl)
	ld (__a_1_store_use_h), hl
	ld hl, (main_p)
	ld (__a_2_store_use_h), hl
	ld a, (g_a)
	ld (__a_3_store_use_h), a
	ld a, (g_v)
	call store_use_h
; 56     store_use_l(g_hl, p, g_a, g_v);
	ld hl, (g_hl)
	ld (__a_1_store_use_l), hl
	ld hl, (main_p)
	ld (__a_2_store_use_l), hl
	ld a, (g_a)
	ld (__a_3_store_use_l), a
	ld a, (g_v)
	call store_use_l
; 57     store_via_bc(g_hl, g_de, p, g_a, g_v);
	ld hl, (g_hl)
	ld (__a_1_store_via_bc), hl
	ld hl, (g_de)
	ld (__a_2_store_via_bc), hl
	ld hl, (main_p)
	ld (__a_3_store_via_bc), hl
	ld a, (g_a)
	ld (__a_4_store_via_bc), a
	ld a, (g_v)
	call store_via_bc
; 58     return 0;
	ld hl, 0
	ret
store_use_b:
; 14 void store_use_b(unsigned hl_keep, u8 *p, u8 a_keep, u8 v) {
	ld (__a_4_store_use_b), a
; 15     *p = v;
	ld hl, (__a_2_store_use_b)
	ld (hl), a
; 16     g_sink = a_keep;
	ld a, (__a_3_store_use_b)
; 17     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_use_b)
	ld (g_sink), a
	ret
store_use_c:
; 20 void store_use_c(unsigned hl_keep, u8 *p, u8 a_keep, u8 v) {
	ld (__a_4_store_use_c), a
; 21     *p = v;
	ld hl, (__a_2_store_use_c)
	ld (hl), a
; 22     g_sink = a_keep;
	ld a, (__a_3_store_use_c)
; 23     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_use_c)
	ld (g_sink), a
	ret
store_use_h:
; 26 void store_use_h(unsigned hl_keep, u8 *p, u8 a_keep, u8 v) {
	ld (__a_4_store_use_h), a
; 27     *p = v;
	ld hl, (__a_2_store_use_h)
	ld (hl), a
; 28     g_sink = a_keep;
	ld a, (__a_3_store_use_h)
	ld (g_sink), a
	ret
store_use_l:
; 31 void store_use_l(unsigned hl_keep, u8 *p, u8 a_keep, u8 v) {
	ld (__a_4_store_use_l), a
; 32     *p = v;
	ld hl, (__a_2_store_use_l)
	ld (hl), a
; 33     g_sink = a_keep;
	ld a, (__a_3_store_use_l)
	ld (g_sink), a
	ret
store_via_bc:
; 36 void store_via_bc(unsigned hl_keep, unsigned de_keep, u8 *p, u8 a_keep, u8 v) {
	ld (__a_5_store_via_bc), a
; 37     *p = v;
	ld hl, (__a_3_store_via_bc)
	ld (hl), a
; 38     g_sink = a_keep;
	ld a, (__a_4_store_via_bc)
; 39     g_sink = (u8)hl_keep;
	ld a, (__a_1_store_via_bc)
; 40     g_sink = (u8)de_keep;
	ld a, (__a_2_store_via_bc)
	ld (g_sink), a
	ret
g_a:
	db 18
g_v:
	db 119
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
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_p equ __s_main + 0
__s_store_use_b equ __static_stack + 0
__a_1_store_use_b equ __s_store_use_b + 0
__a_2_store_use_b equ __s_store_use_b + 2
__a_3_store_use_b equ __s_store_use_b + 4
__a_4_store_use_b equ __s_store_use_b + 5
__s_store_use_c equ __static_stack + 0
__a_1_store_use_c equ __s_store_use_c + 0
__a_2_store_use_c equ __s_store_use_c + 2
__a_3_store_use_c equ __s_store_use_c + 4
__a_4_store_use_c equ __s_store_use_c + 5
__s_store_use_h equ __static_stack + 0
__a_1_store_use_h equ __s_store_use_h + 0
__a_2_store_use_h equ __s_store_use_h + 2
__a_3_store_use_h equ __s_store_use_h + 4
__a_4_store_use_h equ __s_store_use_h + 5
__s_store_use_l equ __static_stack + 0
__a_1_store_use_l equ __s_store_use_l + 0
__a_2_store_use_l equ __s_store_use_l + 2
__a_3_store_use_l equ __s_store_use_l + 4
__a_4_store_use_l equ __s_store_use_l + 5
__s_store_via_bc equ __static_stack + 0
__a_1_store_via_bc equ __s_store_via_bc + 0
__a_2_store_via_bc equ __s_store_via_bc + 2
__a_3_store_via_bc equ __s_store_via_bc + 4
__a_4_store_via_bc equ __s_store_via_bc + 6
__a_5_store_via_bc equ __s_store_via_bc + 7
    savebin "tests\features\59\c8080.bin", __begin, __bss - __begin
