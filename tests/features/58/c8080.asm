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
; 58 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 59     (void)argc; (void)argv;
; 60     const u8 *p = (const u8 *)&g_buf;
	ld hl, g_buf
	ld (main_p), hl
; 61     g_sink = load_use_b(g_hl, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_load_use_b), hl
	ld hl, (main_p)
	ld (__a_2_load_use_b), hl
	ld a, (g_a)
	call load_use_b
	ld (g_sink), a
; 62     g_sink = load_use_c(g_hl, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_load_use_c), hl
	ld hl, (main_p)
	ld (__a_2_load_use_c), hl
	ld a, (g_a)
	call load_use_c
	ld (g_sink), a
; 63     g_sink = load_use_h(g_hl, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_load_use_h), hl
	ld hl, (main_p)
	ld (__a_2_load_use_h), hl
	ld a, (g_a)
	call load_use_h
	ld (g_sink), a
; 64     g_sink = load_use_l(g_hl, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_load_use_l), hl
	ld hl, (main_p)
	ld (__a_2_load_use_l), hl
	ld a, (g_a)
	call load_use_l
	ld (g_sink), a
; 65     g_sink = load_via_bc(g_hl, g_de, p, g_a);
	ld hl, (g_hl)
	ld (__a_1_load_via_bc), hl
	ld hl, (g_de)
	ld (__a_2_load_via_bc), hl
	ld hl, (main_p)
	ld (__a_3_load_via_bc), hl
	ld a, (g_a)
	call load_via_bc
	ld (g_sink), a
; 66     return 0;
	ld hl, 0
	ret
load_use_b:
; 18 u8 load_use_b(unsigned hl_keep, const u8 *p, u8 a_keep) {
	ld (__a_3_load_use_b), a
; 19     u8 v = *p;
	ld hl, (__a_2_load_use_b)
	ld a, (hl)
	ld (load_use_b_v), a
; 20     g_sink = a_keep;
	ld a, (__a_3_load_use_b)
; 21     g_sink = (u8)hl_keep;
	ld a, (__a_1_load_use_b)
	ld (g_sink), a
; 22     return v;
	ld a, (load_use_b_v)
	ret
load_use_c:
; 25 u8 load_use_c(unsigned hl_keep, const u8 *p, u8 a_keep) {
	ld (__a_3_load_use_c), a
; 26     u8 v = *p;
	ld hl, (__a_2_load_use_c)
	ld a, (hl)
	ld (load_use_c_v), a
; 27     g_sink = a_keep;
	ld a, (__a_3_load_use_c)
; 28     g_sink = (u8)hl_keep;
	ld a, (__a_1_load_use_c)
	ld (g_sink), a
; 29     return v;
	ld a, (load_use_c_v)
	ret
load_use_h:
; 32 u8 load_use_h(unsigned hl_keep, const u8 *p, u8 a_keep) {
	ld (__a_3_load_use_h), a
; 33     u8 v = *p;
	ld hl, (__a_2_load_use_h)
	ld a, (hl)
	ld (load_use_h_v), a
; 34     g_sink = a_keep;
	ld a, (__a_3_load_use_h)
	ld (g_sink), a
; 35     return v;
	ld a, (load_use_h_v)
	ret
load_use_l:
; 38 u8 load_use_l(unsigned hl_keep, const u8 *p, u8 a_keep) {
	ld (__a_3_load_use_l), a
; 39     u8 v = *p;
	ld hl, (__a_2_load_use_l)
	ld a, (hl)
	ld (load_use_l_v), a
; 40     g_sink = a_keep;
	ld a, (__a_3_load_use_l)
	ld (g_sink), a
; 41     return v;
	ld a, (load_use_l_v)
	ret
load_via_bc:
; 44 u8 load_via_bc(unsigned hl_keep, unsigned de_keep, const u8 *p, u8 a_keep) {
	ld (__a_4_load_via_bc), a
; 45     u8 v = *p;
	ld hl, (__a_3_load_via_bc)
	ld a, (hl)
	ld (load_via_bc_v), a
; 46     g_sink = a_keep;
	ld a, (__a_4_load_via_bc)
; 47     g_sink = (u8)hl_keep;
	ld a, (__a_1_load_via_bc)
; 48     g_sink = (u8)de_keep;
	ld a, (__a_2_load_via_bc)
	ld (g_sink), a
; 49     return v;
	ld a, (load_via_bc_v)
	ret
g_a:
	db 18
g_hl:
	dw 4660
g_de:
	dw 22136
g_buf:
	db 119
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
__s_load_use_b equ __static_stack + 0
__a_1_load_use_b equ __s_load_use_b + 1
__a_2_load_use_b equ __s_load_use_b + 3
__a_3_load_use_b equ __s_load_use_b + 5
__s_load_use_c equ __static_stack + 0
__a_1_load_use_c equ __s_load_use_c + 1
__a_2_load_use_c equ __s_load_use_c + 3
__a_3_load_use_c equ __s_load_use_c + 5
__s_load_use_h equ __static_stack + 0
__a_1_load_use_h equ __s_load_use_h + 1
__a_2_load_use_h equ __s_load_use_h + 3
__a_3_load_use_h equ __s_load_use_h + 5
__s_load_use_l equ __static_stack + 0
__a_1_load_use_l equ __s_load_use_l + 1
__a_2_load_use_l equ __s_load_use_l + 3
__a_3_load_use_l equ __s_load_use_l + 5
__s_load_via_bc equ __static_stack + 0
__a_1_load_via_bc equ __s_load_via_bc + 1
__a_2_load_via_bc equ __s_load_via_bc + 3
__a_3_load_via_bc equ __s_load_via_bc + 5
__a_4_load_via_bc equ __s_load_via_bc + 7
load_use_b_v equ __s_load_use_b + 0
load_use_c_v equ __s_load_use_c + 0
load_use_h_v equ __s_load_use_h + 0
load_use_l_v equ __s_load_use_l + 0
load_via_bc_v equ __s_load_via_bc + 0
    savebin "tests\features\58\c8080.bin", __begin, __bss - __begin
