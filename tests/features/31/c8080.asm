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
; 30 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 31     use8(sum_add(3, 4));
	ld a, 3
	ld (__a_1_sum_add), a
	ld a, 4
	call sum_add
	call use8
; 32     use8(sum_and(0xF0, 0x0F));
	ld a, 240
	ld (__a_1_sum_and), a
	ld a, 15
	call sum_and
	call use8
; 33     use8(sum_or (0x10, 0x20));
	ld a, 16
	ld (__a_1_sum_or), a
	ld a, 32
	call sum_or
	call use8
; 34     use8(sum_xor(0xAA, 0x55));
	ld a, 170
	ld (__a_1_sum_xor), a
	ld a, 85
	call sum_xor
	call use8
; 35     use8(both_live(7, 9));
	ld a, 7
	ld (__a_1_both_live), a
	ld a, 9
	call both_live
	call use8
; 36     use8(spill_pressure(1, 2, 3, 4));
	ld a, 1
	ld (__a_1_spill_pressure), a
	ld a, 2
	ld (__a_2_spill_pressure), a
	ld a, 3
	ld (__a_3_spill_pressure), a
	ld a, 4
	call spill_pressure
	call use8
; 37     use16(sum16(0x1234, 0x5678));
	ld hl, 4660
	ld (__a_1_sum16), hl
	ld hl, 22136
	call sum16
	call use16
; 38     return 0;
	ld hl, 0
	ret
use8:
; 4 void use8(unsigned char x) { /* stub */ }
	ld (__a_1_use8), a
	ret
sum_add:
; 7 unsigned char sum_add(unsigned char a, unsigned char b) { return a + b; }
	ld (__a_2_sum_add), a
	ld hl, __a_1_sum_add
	add (hl)
	ret
sum_and:
; 8 unsigned char sum_and(unsigned char a, unsigned char b) { return a & b; }
	ld (__a_2_sum_and), a
	ld hl, __a_1_sum_and
	and (hl)
	ret
sum_or:
; 9 unsigned char sum_or (unsigned char a, unsigned char b) { return a | b; }
	ld (__a_2_sum_or), a
	ld hl, __a_1_sum_or
	or (hl)
	ret
sum_xor:
; 10 unsigned char sum_xor(unsigned char a, unsigned char b) { return a ^ b; }
	ld (__a_2_sum_xor), a
	ld hl, __a_1_sum_xor
	xor (hl)
	ret
both_live:
; 14 unsigned char both_live(unsigned char a, unsigned char b) {
	ld (__a_2_both_live), a
; 15     unsigned char s = a + b;
	ld hl, __a_1_both_live
	add (hl)
	ld (both_live_s), a
; 16     g_sink8 = a;
	ld a, (__a_1_both_live)
; 17     g_sink8 = b;
	ld a, (__a_2_both_live)
	ld (g_sink8), a
; 18     return s;
	ld a, (both_live_s)
	ret
spill_pressure:
; 21 unsigned char spill_pressure(unsigned char a, unsigned char b,
	ld (__a_4_spill_pressure), a
; 22                              unsigned char c, unsigned char d) {
; 23     unsigned char t1 = c + d;
	ld hl, __a_3_spill_pressure
	add (hl)
	ld (spill_pressure_t1), a
; 24     g_sink8 = t1;
	ld (g_sink8), a
; 25     return a + b;
	ld hl, __a_1_spill_pressure
	ld a, (__a_2_spill_pressure)
	add (hl)
	ret
use16:
; 5 void use16(unsigned int x) { /* stub */ }
	ld (__a_1_use16), hl
	ret
sum16:
; 28 unsigned int sum16(unsigned int a, unsigned int b) { return a + b; }
	ld (__a_2_sum16), hl
	ld hl, (__a_1_sum16)
	ex hl, de
	ld hl, (__a_2_sum16)
	add hl, de
	ret
__bss:
g_sink8:
	ds 1
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_sum_add equ __static_stack + 0
__a_1_sum_add equ __s_sum_add + 0
__a_2_sum_add equ __s_sum_add + 1
__s_use8 equ __static_stack + 5
__a_1_use8 equ __s_use8 + 0
__s_sum_and equ __static_stack + 0
__a_1_sum_and equ __s_sum_and + 0
__a_2_sum_and equ __s_sum_and + 1
__s_sum_or equ __static_stack + 0
__a_1_sum_or equ __s_sum_or + 0
__a_2_sum_or equ __s_sum_or + 1
__s_sum_xor equ __static_stack + 0
__a_1_sum_xor equ __s_sum_xor + 0
__a_2_sum_xor equ __s_sum_xor + 1
__s_both_live equ __static_stack + 0
__a_1_both_live equ __s_both_live + 1
__a_2_both_live equ __s_both_live + 2
__s_spill_pressure equ __static_stack + 0
__a_1_spill_pressure equ __s_spill_pressure + 1
__a_2_spill_pressure equ __s_spill_pressure + 2
__a_3_spill_pressure equ __s_spill_pressure + 3
__a_4_spill_pressure equ __s_spill_pressure + 4
__s_sum16 equ __static_stack + 0
__a_1_sum16 equ __s_sum16 + 0
__a_2_sum16 equ __s_sum16 + 2
__s_use16 equ __static_stack + 4
__a_1_use16 equ __s_use16 + 0
both_live_s equ __s_both_live + 0
spill_pressure_t1 equ __s_spill_pressure + 0
    savebin "tests\features\31\c8080.bin", __begin, __bss - __begin
