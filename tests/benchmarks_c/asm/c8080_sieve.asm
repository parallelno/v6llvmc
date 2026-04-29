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
; 40     (void)argc; (void)argv;
; 41     u8 i;
; 42 
; 43     init_buf();
	call init_buf
; 44     for (i = 2; i < 16; i++) {
	ld a, 2
	ld (main_i), a
l_0:
	cp 16
	jp nc, l_2
; 45         if (buf[i]) cross_off(i);
	ld de, buf
	ld hl, (main_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	or a
	jp z, l_3
	ld a, (main_i)
	call cross_off
l_3:
	ld a, (main_i)
	inc a
	ld (main_i), a
	jp l_0
l_2:
; 46     }
; 47     bench_finish(count_set());
	call count_set
	call bench_finish
; 48     return 0;
	ld hl, 0
	ret
init_buf:
; 16 static NOINLINE void init_buf(void) {
; 17     u8 i;
; 18     for (i = 0; i < N; i++) buf[i] = 1;
	xor a
	ld (init_buf_i), a
l_5:
	cp 252
	jp nc, l_7
	ld de, buf
	ld hl, (init_buf_i)
	ld h, 0
	add hl, de
	ld (hl), 1
	inc a
	ld (init_buf_i), a
	jp l_5
l_7:
; 19     buf[0] = 0;
	xor a
	ld (buf), a
; 20     buf[1] = 0;
	ld (0FFFFh & ((buf) + (1))), a
	ret
cross_off:
; 23 static NOINLINE void cross_off(u8 p) {
	ld (__a_1_cross_off), a
; 24     /* Walk multiples of p starting at 2*p, using u16 index so codegen
; 25      * stays simple (no overflow wrap to reason about). */
; 26     u16 j;
; 27     for (j = (u16)p + p; j < N; j = (u16)(j + p)) {
	ld hl, (__a_1_cross_off)
	ld h, 0
	ex hl, de
	ld hl, (__a_1_cross_off)
	ld h, 0
	add hl, de
	ld (cross_off_j), hl
l_8:
	ld de, 65284
	add hl, de
	ret c
; 28         buf[j] = 0;
	ld de, buf
	ld hl, (cross_off_j)
	add hl, de
	xor a
	ld (hl), a
	ld hl, (cross_off_j)
	ex hl, de
	ld hl, (__a_1_cross_off)
	ld h, 0
	add hl, de
	ld (cross_off_j), hl
	jp l_8
bench_finish:
; 42 void __global bench_finish(unsigned char checksum) {
	ld (__a_1_bench_finish), a
; 43     asm {

        out  (0xED), a
        halt

	ret
count_set:
; 32 static NOINLINE u8 count_set(void) {
; 33     u8 c = 0;
	xor a
	ld (count_set_c), a
; 34     u8 i;
; 35     for (i = 0; i < N; i++) if (buf[i]) c = (u8)(c + 1);
	ld (count_set_i), a
l_11:
	cp 252
	jp nc, l_13
	ld de, buf
	ld hl, (count_set_i)
	ld h, 0
	add hl, de
	ld a, (hl)
	or a
	jp z, l_14
	ld a, (count_set_c)
	inc a
	ld (count_set_c), a
l_14:
	ld a, (count_set_i)
	inc a
	ld (count_set_i), a
	jp l_11
l_13:
; 36     return c;
	ld a, (count_set_c)
	ret
__bss:
buf:
	ds 252
__static_stack:
	ds 8
__end:
__s___init equ __static_stack + 8
__s_main equ __static_stack + 3
__a_1_main equ __s_main + 1
__a_2_main equ __s_main + 3
main_i equ __s_main + 0
__s_cross_off equ __static_stack + 0
__a_1_cross_off equ __s_cross_off + 2
__s_bench_finish equ __static_stack + 2
__a_1_bench_finish equ __s_bench_finish + 0
__s_init_buf equ __static_stack + 0
init_buf_i equ __s_init_buf + 0
cross_off_j equ __s_cross_off + 0
__s_count_set equ __static_stack + 0
count_set_c equ __s_count_set + 0
count_set_i equ __s_count_set + 1
    savebin "C:\Work\Programming\v6llvmc\tests\benchmarks_c\build\c8080_sieve.com", __begin, __bss - __begin
