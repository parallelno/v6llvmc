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
; 39 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 40     buf[0] = 0x1234;
	ld hl, 4660
	ld (buf), hl
; 41     buf[1] = 0x5678;
	ld hl, 22136
	ld (0FFFFh & ((buf) + (2))), hl
; 42 
; 43     g_r = bug3_de_de(0x1000, &buf[0]);
	ld hl, 4096
	ld (__a_1_bug3_de_de), hl
	ld hl, buf
	call bug3_de_de
	ld (g_r), hl
; 44     g_byte = (uint8_t)g_r;
	ld a, (g_r)
	ld (g_byte), a
; 45 
; 46     g_r = case2_hl_reused(&buf[1]);
	ld hl, 0FFFFh & ((buf) + (2))
	call case2_hl_reused
	ld (g_r), hl
; 47     g_r = case5_bc_with_hl_live(&buf[0], 0x0001);
	ld hl, buf
	ld (__a_1_case5_bc_with_hl_live), hl
	ld hl, 1
	call case5_bc_with_hl_live
	ld (g_r), hl
; 48     g_byte = case16_a_live(&buf[1], 0x42);
	ld hl, 0FFFFh & ((buf) + (2))
	ld (__a_1_case16_a_live), hl
	ld a, 66
	call case16_a_live
	ld (g_byte), a
; 49 
; 50     return 0;
	ld hl, 0
	ret
bug3_de_de:
; 16 uint16_t bug3_de_de(uint16_t sum_in_hl, uint16_t *p_in_de) {
	ld (__a_2_bug3_de_de), hl
; 17     uint16_t v = *p_in_de;
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (bug3_de_de_v), hl
; 18     return sum_in_hl + v;
	ld hl, (__a_1_bug3_de_de)
	ex hl, de
	ld hl, (bug3_de_de_v)
	add hl, de
	ret
case2_hl_reused:
; 21 uint16_t case2_hl_reused(uint16_t *p) {
	ld (__a_1_case2_hl_reused), hl
; 22     uint16_t lo = p[0];
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (case2_hl_reused_lo), hl
; 23     uint16_t hi = p[0];
	ld hl, (__a_1_case2_hl_reused)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (case2_hl_reused_hi), hl
; 24     return lo + hi;
	ld hl, (case2_hl_reused_lo)
	ex hl, de
	ld hl, (case2_hl_reused_hi)
	add hl, de
	ret
case5_bc_with_hl_live:
; 27 uint16_t case5_bc_with_hl_live(uint16_t *p, uint16_t hl_keep) {
	ld (__a_2_case5_bc_with_hl_live), hl
; 28     uint16_t v = *p;
	ld hl, (__a_1_case5_bc_with_hl_live)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (case5_bc_with_hl_live_v), hl
; 29     return v + hl_keep;
	ex hl, de
	ld hl, (__a_2_case5_bc_with_hl_live)
	add hl, de
	ret
case16_a_live:
; 32 uint8_t case16_a_live(uint16_t *p, uint8_t a_keep) {
	ld (__a_2_case16_a_live), a
; 33     uint16_t v = *p;
	ld hl, (__a_1_case16_a_live)
	ld e, (hl)
	inc hl
	ld d, (hl)
	ex hl, de
	ld (case16_a_live_v), hl
; 34     return (uint8_t)(v >> 8) ^ a_keep;
	ld d, h
	xor d
	ret
__bss:
g_r:
	ds 2
g_byte:
	ds 1
buf:
	ds 4
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_bug3_de_de equ __static_stack + 0
__a_1_bug3_de_de equ __s_bug3_de_de + 2
__a_2_bug3_de_de equ __s_bug3_de_de + 4
__s_case2_hl_reused equ __static_stack + 0
__a_1_case2_hl_reused equ __s_case2_hl_reused + 4
__s_case5_bc_with_hl_live equ __static_stack + 0
__a_1_case5_bc_with_hl_live equ __s_case5_bc_with_hl_live + 2
__a_2_case5_bc_with_hl_live equ __s_case5_bc_with_hl_live + 4
__s_case16_a_live equ __static_stack + 0
__a_1_case16_a_live equ __s_case16_a_live + 2
__a_2_case16_a_live equ __s_case16_a_live + 4
bug3_de_de_v equ __s_bug3_de_de + 0
case2_hl_reused_lo equ __s_case2_hl_reused + 0
case2_hl_reused_hi equ __s_case2_hl_reused + 2
case5_bc_with_hl_live_v equ __s_case5_bc_with_hl_live + 0
case16_a_live_v equ __s_case16_a_live + 0
    savebin "tests\features\53\c8080.bin", __begin, __bss - __begin
