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
; 29     (void)argc; (void)argv;
; 30     g_sink = fold_add(0x10);
	ld a, 16
	call fold_add
	ld (g_sink), a
; 31     g_sink = fold_sub(0x10);
	ld a, 16
	call fold_sub
	ld (g_sink), a
; 32     g_sink = fold_and(0xAB);
	ld a, 171
	call fold_and
	ld (g_sink), a
; 33     g_sink = fold_or(0xAA);
	ld a, 170
	call fold_or
	ld (g_sink), a
; 34     g_sink = fold_xor(0xAA);
	ld a, 170
	call fold_xor
	ld (g_sink), a
; 35     g_sink = (u8)fold_cmp(0x42);
	ld a, 66
	call fold_cmp
	ld a, l
	ld (g_sink), a
; 36     g_sink = fold_chain(0x07);
	ld a, 7
	call fold_chain
	ld (g_sink), a
; 37     g_sink = fold_spill(1, 2, 3, 4, 5, 6, 7, 8);
	ld a, 1
	ld (__a_1_fold_spill), a
	ld a, 2
	ld (__a_2_fold_spill), a
	ld a, 3
	ld (__a_3_fold_spill), a
	ld a, 4
	ld (__a_4_fold_spill), a
	ld a, 5
	ld (__a_5_fold_spill), a
	ld a, 6
	ld (__a_6_fold_spill), a
	ld a, 7
	ld (__a_7_fold_spill), a
	ld a, 8
	call fold_spill
	ld (g_sink), a
; 38     return 0;
	ld hl, 0
	ret
fold_add:
; 9 u8 fold_add(u8 a) { return a + 0x0F; }
	ld (__a_1_fold_add), a
	add 15
	ret
fold_sub:
; 10 u8 fold_sub(u8 a) { return a - 0x05; }
	ld (__a_1_fold_sub), a
	add 251
	ret
fold_and:
; 11 u8 fold_and(u8 a) { return a & 0xF0; }
	ld (__a_1_fold_and), a
	and 240
	ret
fold_or:
; 12 u8 fold_or (u8 a) { return a | 0x01; }
	ld (__a_1_fold_or), a
	or 1
	ret
fold_xor:
; 13 u8 fold_xor(u8 a) { return a ^ 0x55; }
	ld (__a_1_fold_xor), a
	xor 85
	ret
fold_cmp:
; 14 int fold_cmp(u8 a) { return (a == 0x42) ? 1 : 0; }
	ld (__a_1_fold_cmp), a
	cp 66
	jp nz, l_0
	ld hl, 1
	ret
l_0:
	ld hl, 0
	ret
fold_chain:
; 15 u8 fold_chain(u8 a) { return ((a + 5) & 0xF0) ^ 0x10; }
	ld (__a_1_fold_chain), a
	add 5
	and 240
	xor 16
	ret
fold_spill:
; 17 u8 fold_spill(u8 x0, u8 x1, u8 x2, u8 x3,
	ld (__a_8_fold_spill), a
; 18               u8 x4, u8 x5, u8 x6, u8 x7) {
; 19     u8 s = x0;
	ld a, (__a_1_fold_spill)
	ld (fold_spill_s), a
; 20     s ^= x1; s ^= x2; s ^= x3;
	ld hl, fold_spill_s
	ld a, (__a_2_fold_spill)
	xor (hl)
	ld (hl), a
	ld a, (__a_3_fold_spill)
	xor (hl)
	ld (hl), a
	ld a, (__a_4_fold_spill)
	xor (hl)
	ld (hl), a
; 21     s ^= x4; s ^= x5; s ^= x6;
	ld a, (__a_5_fold_spill)
	xor (hl)
	ld (hl), a
	ld a, (__a_6_fold_spill)
	xor (hl)
	ld (hl), a
	ld a, (__a_7_fold_spill)
	xor (hl)
	ld (hl), a
; 22     s ^= x7;
	ld a, (__a_8_fold_spill)
	xor (hl)
	ld (hl), a
; 23     return s;
	ret
__bss:
g_sink:
	ds 1
__static_stack:
	ds 13
__end:
__s___init equ __static_stack + 13
__s_main equ __static_stack + 9
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_fold_add equ __static_stack + 0
__a_1_fold_add equ __s_fold_add + 0
__s_fold_sub equ __static_stack + 0
__a_1_fold_sub equ __s_fold_sub + 0
__s_fold_and equ __static_stack + 0
__a_1_fold_and equ __s_fold_and + 0
__s_fold_or equ __static_stack + 0
__a_1_fold_or equ __s_fold_or + 0
__s_fold_xor equ __static_stack + 0
__a_1_fold_xor equ __s_fold_xor + 0
__s_fold_cmp equ __static_stack + 0
__a_1_fold_cmp equ __s_fold_cmp + 0
__s_fold_chain equ __static_stack + 0
__a_1_fold_chain equ __s_fold_chain + 0
__s_fold_spill equ __static_stack + 0
__a_1_fold_spill equ __s_fold_spill + 1
__a_2_fold_spill equ __s_fold_spill + 2
__a_3_fold_spill equ __s_fold_spill + 3
__a_4_fold_spill equ __s_fold_spill + 4
__a_5_fold_spill equ __s_fold_spill + 5
__a_6_fold_spill equ __s_fold_spill + 6
__a_7_fold_spill equ __s_fold_spill + 7
__a_8_fold_spill equ __s_fold_spill + 8
fold_spill_s equ __s_fold_spill + 0
    savebin "tests\features\61\c8080.bin", __begin, __bss - __begin
