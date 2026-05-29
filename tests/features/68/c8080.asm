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
; 25 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 26   (void)argc;
; 27   (void)argv;
; 28 
; 29   g_out_u = shl_u16_3(g_u);
	ld hl, (g_u)
	call shl_u16_3
	ld (g_out_u), hl
; 30   g_out_u = shl_u16_9(g_u);
	ld hl, (g_u)
	call shl_u16_9
	ld (g_out_u), hl
; 31   g_out_u = shl_u16_13(g_u);
	ld hl, (g_u)
	call shl_u16_13
	ld (g_out_u), hl
; 32   g_out_u = shl_u16_15(g_u);
	ld hl, (g_u)
	call shl_u16_15
	ld (g_out_u), hl
; 33 
; 34   g_out_u = shr_u16_1(g_u);
	ld hl, (g_u)
	call shr_u16_1
	ld (g_out_u), hl
; 35   g_out_u = shr_u16_2(g_u);
	ld hl, (g_u)
	call shr_u16_2
	ld (g_out_u), hl
; 36   g_out_u = shr_u16_7(g_u);
	ld hl, (g_u)
	call shr_u16_7
	ld (g_out_u), hl
; 37   g_out_u = shr_u16_9(g_u);
	ld hl, (g_u)
	call shr_u16_9
	ld (g_out_u), hl
; 38   g_out_u = shr_u16_15(g_u);
	ld hl, (g_u)
	call shr_u16_15
	ld (g_out_u), hl
; 39 
; 40   g_out_s = sar_i16_7(g_s);
	ld hl, (g_s)
	call sar_i16_7
	ld (g_out_s), hl
; 41   g_out_s = sar_i16_9(g_s);
	ld hl, (g_s)
	call sar_i16_9
	ld (g_out_s), hl
; 42   g_out_s = sar_i16_15(g_s);
	ld hl, (g_s)
	call sar_i16_15
	ld (g_out_s), hl
; 43   return 0;
	ld hl, 0
	ret
shl_u16_3:
; 5 u16 shl_u16_3(u16 x) { return (u16)(x << 3); }
	ld (__a_1_shl_u16_3), hl
	add hl, hl
	add hl, hl
	add hl, hl
	ret
shl_u16_9:
; 6 u16 shl_u16_9(u16 x) { return (u16)(x << 9); }
	ld (__a_1_shl_u16_9), hl
	ld h, l
	ld l, 0
	add hl, hl
	ret
shl_u16_13:
; 7 u16 shl_u16_13(u16 x) { return (u16)(x << 13); }
	ld (__a_1_shl_u16_13), hl
	ld h, l
	ld l, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ret
shl_u16_15:
; 8 u16 shl_u16_15(u16 x) { return (u16)(x << 15); }
	ld (__a_1_shl_u16_15), hl
	ld h, l
	ld l, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ret
shr_u16_1:
; 10 u16 shr_u16_1(u16 x) { return (u16)(x >> 1); }
	ld (__a_1_shr_u16_1), hl
	ld de, 1
	jp __o_shr_u16
shr_u16_2:
; 11 u16 shr_u16_2(u16 x) { return (u16)(x >> 2); }
	ld (__a_1_shr_u16_2), hl
	ld de, 2
	jp __o_shr_u16
shr_u16_7:
; 12 u16 shr_u16_7(u16 x) { return (u16)(x >> 7); }
	ld (__a_1_shr_u16_7), hl
	ld de, 7
	jp __o_shr_u16
shr_u16_9:
; 13 u16 shr_u16_9(u16 x) { return (u16)(x >> 9); }
	ld (__a_1_shr_u16_9), hl
	ld de, 9
	jp __o_shr_u16
shr_u16_15:
; 14 u16 shr_u16_15(u16 x) { return (u16)(x >> 15); }
	ld (__a_1_shr_u16_15), hl
	ld de, 15
	jp __o_shr_u16
sar_i16_7:
; 16 s16 sar_i16_7(s16 x) { return (s16)(x >> 7); }
	ld (__a_1_sar_i16_7), hl
	ld de, 7
	jp __o_shr_i16
sar_i16_9:
; 17 s16 sar_i16_9(s16 x) { return (s16)(x >> 9); }
	ld (__a_1_sar_i16_9), hl
	ld de, 9
	jp __o_shr_i16
sar_i16_15:
; 18 s16 sar_i16_15(s16 x) { return (s16)(x >> 15); }
	ld (__a_1_sar_i16_15), hl
	ld de, 15
	jp __o_shr_i16
__o_shr_u16:
; 521 void __o_shr_u16() {
; 522     asm {

        inc  e
__o_shr_u16__l1:
        dec  e
        ret  z
        ld   a, h
        or   a    ; cf = 0
        rra
        ld   h, a
        ld   a, l
        rra
        ld   l, a
        jp   __o_shr_u16__l1
1

	ret
__o_shr_i16:
; 543 void __o_shr_i16() {
; 544     asm {

        inc  e
__o_shr_i16__l1:
        dec  e
        ret  z
        ld   a, h
        rla
        ld   a, h
        rra
        ld   h, a
        ld   a, l
        rra
        ld   l, a
        jp   __o_shr_i16__l1

	ret
g_u:
	dw 37428
g_s:
	dw 37428
__bss:
g_out_u:
	ds 2
g_out_s:
	ds 2
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_shl_u16_3 equ __static_stack + 0
__a_1_shl_u16_3 equ __s_shl_u16_3 + 0
__s_shl_u16_9 equ __static_stack + 0
__a_1_shl_u16_9 equ __s_shl_u16_9 + 0
__s_shl_u16_13 equ __static_stack + 0
__a_1_shl_u16_13 equ __s_shl_u16_13 + 0
__s_shl_u16_15 equ __static_stack + 0
__a_1_shl_u16_15 equ __s_shl_u16_15 + 0
__s_shr_u16_1 equ __static_stack + 0
__a_1_shr_u16_1 equ __s_shr_u16_1 + 0
__s_shr_u16_2 equ __static_stack + 0
__a_1_shr_u16_2 equ __s_shr_u16_2 + 0
__s_shr_u16_7 equ __static_stack + 0
__a_1_shr_u16_7 equ __s_shr_u16_7 + 0
__s_shr_u16_9 equ __static_stack + 0
__a_1_shr_u16_9 equ __s_shr_u16_9 + 0
__s_shr_u16_15 equ __static_stack + 0
__a_1_shr_u16_15 equ __s_shr_u16_15 + 0
__s_sar_i16_7 equ __static_stack + 0
__a_1_sar_i16_7 equ __s_sar_i16_7 + 0
__s_sar_i16_9 equ __static_stack + 0
__a_1_sar_i16_9 equ __s_sar_i16_9 + 0
__s_sar_i16_15 equ __static_stack + 0
__a_1_sar_i16_15 equ __s_sar_i16_15 + 0
__s___o_shr_u16 equ __static_stack + 0
__s___o_shr_i16 equ __static_stack + 0
    savebin "tests\features\68\c8080.bin", __begin, __bss - __begin
