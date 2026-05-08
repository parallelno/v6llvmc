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
; 51 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 52     (void)argc; (void)argv;
; 53     g_out  = dec_loop(g_n);
	ld a, (g_n)
	call dec_loop
	ld (g_out), hl
; 54     g_outb = mask_test(g_x);
	ld a, (g_x)
	call mask_test
	ld (g_outb), a
; 55     g_outb = xor_test(g_x, g_y);
	ld a, (g_x)
	ld (__a_1_xor_test), a
	ld a, (g_y)
	call xor_test
	ld (g_outb), a
; 56     g_outb = sub_test(g_x);
	ld a, (g_x)
	call sub_test
	ld (g_outb), a
; 57     g_out  = dec_loop_used(g_n);
	ld a, (g_n)
	call dec_loop_used
	ld (g_out), hl
; 58     return 0;
	ld hl, 0
	ret
dec_loop:
; 12 u16 dec_loop(u8 n) {
	ld (__a_1_dec_loop), a
; 13     u16 sum = 0;
	ld hl, 0
	ld (dec_loop_sum), hl
; 14     while (n) { g_sink = n; sum += n; --n; }
l_0:
	or a
	jp z, l_1
	ld (g_sink), a
	ex hl, de
	ld hl, (__a_1_dec_loop)
	ld h, 0
	add hl, de
	ld (dec_loop_sum), hl
	ld a, (__a_1_dec_loop)
	dec a
	ld (__a_1_dec_loop), a
	jp l_0
l_1:
; 15     return sum;
	ld hl, (dec_loop_sum)
	ret
mask_test:
; 20 u8 mask_test(u8 x) {
	ld (__a_1_mask_test), a
; 21     return (x & 0x0F) == 0 ? (u8)1 : (u8)0;
	and 15
	jp nz, l_2
	ld a, 1
	ret
l_2:
	xor a
	ret
xor_test:
; 25 u8 xor_test(u8 x, u8 y) {
	ld (__a_2_xor_test), a
; 26     u8 z = x ^ y;
	ld hl, __a_1_xor_test
	xor (hl)
	ld (xor_test_z), a
; 27     g_sink = z;
	ld (g_sink), a
; 28     return z != 0 ? (u8)1 : (u8)0;
	ld a, (xor_test_z)
	or a
	jp z, l_4
	ld a, 1
	ret
l_4:
	xor a
	ret
sub_test:
; 31 u8 sub_test(u8 x) {
	ld (__a_1_sub_test), a
; 32     u8 z = x - 5;
	add 251
	ld (sub_test_z), a
; 33     g_sink = z;
	ld (g_sink), a
; 34     return z != 0 ? (u8)1 : (u8)0;
	ld a, (sub_test_z)
	or a
	jp z, l_6
	ld a, 1
	ret
l_6:
	xor a
	ret
dec_loop_used:
; 38 u16 dec_loop_used(u8 n) {
	ld (__a_1_dec_loop_used), a
; 39     u16 sum = 0;
	ld hl, 0
	ld (dec_loop_used_sum), hl
; 40     while (n) { g_sink = n; sum += n; --n; }
l_8:
	or a
	jp z, l_9
	ld (g_sink), a
	ex hl, de
	ld hl, (__a_1_dec_loop_used)
	ld h, 0
	add hl, de
	ld (dec_loop_used_sum), hl
	ld a, (__a_1_dec_loop_used)
	dec a
	ld (__a_1_dec_loop_used), a
	jp l_8
l_9:
; 41     return sum + (u16)n;
	ld hl, (dec_loop_used_sum)
	ex hl, de
	ld hl, (__a_1_dec_loop_used)
	ld h, 0
	add hl, de
	ret
g_n:
	db 7
g_x:
	db 51
g_y:
	db 51
__bss:
g_sink:
	ds 1
g_out:
	ds 2
g_outb:
	ds 1
__static_stack:
	ds 7
__end:
__s___init equ __static_stack + 7
__s_main equ __static_stack + 3
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_dec_loop equ __static_stack + 0
__a_1_dec_loop equ __s_dec_loop + 2
__s_mask_test equ __static_stack + 0
__a_1_mask_test equ __s_mask_test + 0
__s_xor_test equ __static_stack + 0
__a_1_xor_test equ __s_xor_test + 1
__a_2_xor_test equ __s_xor_test + 2
__s_sub_test equ __static_stack + 0
__a_1_sub_test equ __s_sub_test + 1
__s_dec_loop_used equ __static_stack + 0
__a_1_dec_loop_used equ __s_dec_loop_used + 2
dec_loop_sum equ __s_dec_loop + 0
xor_test_z equ __s_xor_test + 0
sub_test_z equ __s_sub_test + 0
dec_loop_used_sum equ __s_dec_loop_used + 0
    savebin "tests\features\57\c8080.bin", __begin, __bss - __begin
