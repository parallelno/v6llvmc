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
; 47 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 48     volatile u8  a = repro();
	call repro
	ld (main_a), a
; 49     volatile u16 b = walk16(buf, 4);
	ld hl, buf
	ld (__a_1_walk16), hl
	ld a, 4
	call walk16
	ld (main_b), hl
; 50     return 0;
	ld hl, 0
	ret
repro:
; 10 u8 repro(void) {
; 11     volatile u8 seed = 7;
	ld a, 7
	ld (repro_seed), a
; 12     u8 n = seed;
	ld (repro_n), a
; 13     u8 i, r;
; 14 
; 15     for (i = 0; i < n; i++)
	xor a
	ld (repro_i), a
l_0:
	ld hl, repro_n
	cp (hl)
	jp nc, l_2
; 16         perm1[i] = i;
	ld de, perm1
	ld hl, (repro_i)
	ld h, 0
	add hl, de
	ld (hl), a
	inc a
	ld (repro_i), a
	jp l_0
l_2:
; 17     r = n;
	ld a, (repro_n)
	ld (repro_r), a
; 18 
; 19     for (;;) {
l_3:
; 20         while (r != 1) {
l_6:
	cp 1
	jp z, l_7
; 21             count[r - 1] = r;
	ld de, count
	ld hl, (repro_r)
	ld h, 0
	dec hl
	add hl, de
	ld (hl), a
; 22             r--;
	dec a
	ld (repro_r), a
	jp l_6
l_7:
; 23         }
; 24         if (r == n)
	ld hl, repro_r
	ld a, (repro_n)
	cp (hl)
	jp nz, l_8
; 25             return r;
	ld a, (repro_r)
	ret
l_8:
; 26         count[r] = (u8)(count[r] - 1);
	ld de, count
	ld hl, (repro_r)
	ld h, 0
	add hl, de
	ld a, (hl)
	dec a
	ld hl, (repro_r)
	ld h, 0
	add hl, de
	ld (hl), a
; 27         r++;
	ld a, (repro_r)
	inc a
	ld (repro_r), a
	jp l_3
walk16:
; 33 u16 walk16(u16 *p, u8 n) {
	ld (__a_2_walk16), a
; 34     volatile u8 seed = n;
	ld (walk16_seed), a
; 35     u8 m = seed;
	ld (walk16_m), a
; 36     u16 acc = 0;
	ld hl, 0
	ld (walk16_acc), hl
; 37     u8 i;
; 38     for (i = 0; i < m; i++)
	xor a
	ld (walk16_i), a
l_10:
	ld hl, walk16_m
	cp (hl)
	jp nc, l_12
; 39         acc = (u16)(acc + p[i]);
	ld hl, (__a_1_walk16)
	ex hl, de
	ld hl, (walk16_i)
	ld h, 0
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld hl, (walk16_acc)
	add hl, de
	ld (walk16_acc), hl
	inc a
	ld (walk16_i), a
	jp l_10
l_12:
; 40     for (i = 0; i < m; i++)
	xor a
	ld (walk16_i), a
l_13:
	ld hl, walk16_m
	cp (hl)
	jp nc, l_15
; 41         acc = (u16)(acc ^ p[i]);
	ld hl, (__a_1_walk16)
	ex hl, de
	ld hl, (walk16_i)
	ld h, 0
	add hl, hl
	add hl, de
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld hl, (walk16_acc)
	call __o_xor_16
	ld (walk16_acc), hl
	ld a, (walk16_i)
	inc a
	ld (walk16_i), a
	jp l_13
l_15:
; 42     return acc;
	ld hl, (walk16_acc)
	ret
__o_xor_16:
; 310 void __o_xor_16() {
; 311     asm {

        ld   a, h
        xor  d
        ld   h, a
        ld   a, l
        xor  e
        ld   l, a
        or   h         ; Flag Z used for compare

	ret
__bss:
perm1:
	ds 8
count:
	ds 8
buf:
	ds 16
__static_stack:
	ds 15
__end:
__s___init equ __static_stack + 15
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 3
__a_2_main equ __s_main + 5
main_a equ __s_main + 0
main_b equ __s_main + 1
__s_walk16 equ __static_stack + 0
__a_1_walk16 equ __s_walk16 + 5
__a_2_walk16 equ __s_walk16 + 7
__s_repro equ __static_stack + 0
repro_seed equ __s_repro + 0
repro_n equ __s_repro + 1
repro_i equ __s_repro + 2
repro_r equ __s_repro + 3
walk16_seed equ __s_walk16 + 0
walk16_m equ __s_walk16 + 1
walk16_acc equ __s_walk16 + 2
walk16_i equ __s_walk16 + 4
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\76\c8080.bin", __begin, __bss - __begin
