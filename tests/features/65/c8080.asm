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
; 34 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 35     (void)argc; (void)argv;
; 36     u16 c = sieve_count(200);
	ld hl, 200
	call sieve_count
	ld (main_c), hl
; 37     return (int)((u8)c ^ (u8)(c >> 8));
	ld a, (main_c)
	ld d, h
	xor d
	ld l, a
	ld h, 0
	ret
sieve_count:
; 15 u16 sieve_count(u16 n) {
	ld (__a_1_sieve_count), hl
; 16     u16 i, k, count, i_sq;
; 17 
; 18     for (k = 0; k < n; k++) flags[k] = 0;
	ld hl, 0
	ld (sieve_count_k), hl
l_0:
	ld hl, (__a_1_sieve_count)
	ex hl, de
	ld hl, (sieve_count_k)
	call __o_sub_16
	jp nc, l_2
	ld de, flags
	ld hl, (sieve_count_k)
	add hl, de
	xor a
	ld (hl), a
	ld hl, (sieve_count_k)
	inc hl
	ld (sieve_count_k), hl
	jp l_0
l_2:
; 19 
; 20     count = (u16)(n - 2);
	ld hl, (__a_1_sieve_count)
	dec hl
	dec hl
	ld (sieve_count_count), hl
; 21     i_sq  = 4;
	ld hl, 4
	ld (sieve_count_i_sq), hl
; 22     for (i = 2; i_sq < n; ++i) {
	ld hl, 2
	ld (sieve_count_i), hl
l_3:
	ld hl, (__a_1_sieve_count)
	ex hl, de
	ld hl, (sieve_count_i_sq)
	call __o_sub_16
	jp nc, l_5
; 23         if (!flags[i]) {
	ld de, flags
	ld hl, (sieve_count_i)
	add hl, de
	ld a, (hl)
	or a
	jp nz, l_6
; 24             for (k = i_sq; k < n; k = (u16)(k + i)) {
	ld hl, (sieve_count_i_sq)
	ld (sieve_count_k), hl
l_8:
	ld hl, (__a_1_sieve_count)
	ex hl, de
	ld hl, (sieve_count_k)
	call __o_sub_16
	jp nc, l_10
; 25                 if (!flags[k]) count = (u16)(count - 1);
	ld de, flags
	ld hl, (sieve_count_k)
	add hl, de
	ld a, (hl)
	or a
	jp nz, l_11
	ld hl, (sieve_count_count)
	dec hl
	ld (sieve_count_count), hl
l_11:
; 26                 flags[k] = 1;
	ld hl, (sieve_count_k)
	add hl, de
	ld (hl), 1
	ld hl, (sieve_count_k)
	ex hl, de
	ld hl, (sieve_count_i)
	add hl, de
	ld (sieve_count_k), hl
	jp l_8
l_10:
l_6:
; 27             }
; 28         }
; 29         i_sq = (u16)(i_sq + i + i + 1);
	ld hl, (sieve_count_i_sq)
	ex hl, de
	ld hl, (sieve_count_i)
	add hl, de
	ex hl, de
	ld hl, (sieve_count_i)
	add hl, de
	inc hl
	ld (sieve_count_i_sq), hl
	ld hl, (sieve_count_i)
	inc hl
	ld (sieve_count_i), hl
	jp l_3
l_5:
; 30     }
; 31     return count;
	ld hl, (sieve_count_count)
	ret
__o_sub_16:
; 265 void __o_sub_16() {
; 266     asm {

        ld   a, l
        sub  e
        ld   l, a
        ld   a, h
        sbc  d
        ld   h, a

	ret
__bss:
flags:
	ds 200
__static_stack:
	ds 16
__end:
__s___init equ __static_stack + 16
__s_main equ __static_stack + 10
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_c equ __s_main + 0
__s_sieve_count equ __static_stack + 0
__a_1_sieve_count equ __s_sieve_count + 8
sieve_count_k equ __s_sieve_count + 2
sieve_count_count equ __s_sieve_count + 4
sieve_count_i_sq equ __s_sieve_count + 6
sieve_count_i equ __s_sieve_count + 0
__s___o_sub_16 equ __static_stack + 0
    savebin "tests\features\65\c8080.bin", __begin, __bss - __begin
