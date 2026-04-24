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
; 53 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 54     unsigned char a = 0x10;
	ld a, 16
	ld (main_a), a
; 55     a = add_m(a, buf);
	ld (__a_1_add_m), a
	ld hl, buf
	call add_m
	ld (main_a), a
; 56     a = sub_m(a, buf + 1);
	ld (__a_1_sub_m), a
	ld hl, 0FFFFh & ((buf) + (1))
	call sub_m
	ld (main_a), a
; 57     a = and_m(a, buf + 2);
	ld (__a_1_and_m), a
	ld hl, 0FFFFh & ((buf) + (2))
	call and_m
	ld (main_a), a
; 58     a = or_m(a, buf + 3);
	ld (__a_1_or_m), a
	ld hl, 0FFFFh & ((buf) + (3))
	call or_m
	ld (main_a), a
; 59     a = xor_m(a, buf);
	ld (__a_1_xor_m), a
	ld hl, buf
	call xor_m
	ld (main_a), a
; 60     cmp_m(a, buf);
	ld (__a_1_cmp_m), a
	ld hl, buf
	call cmp_m
; 61     store_imm(buf);
	ld hl, buf
	call store_imm
; 62     inc_m(buf + 1);
	ld hl, 0FFFFh & ((buf) + (1))
	call inc_m
; 63     dec_m(buf + 2);
	ld hl, 0FFFFh & ((buf) + (2))
	call dec_m
; 64     return sum_bytes(buf, 4);
	ld hl, buf
	ld (__a_1_sum_bytes), hl
	ld a, 4
	call sum_bytes
	ld l, a
	ld h, 0
	ret
add_m:
; 8 unsigned char add_m(unsigned char a, unsigned char *p) {
	ld (__a_2_add_m), hl
; 9     return a + *p;
	ld a, (__a_1_add_m)
	add (hl)
	ret
sub_m:
; 12 unsigned char sub_m(unsigned char a, unsigned char *p) {
	ld (__a_2_sub_m), hl
; 13     return a - *p;
	ld a, (__a_1_sub_m)
	sub (hl)
	ret
and_m:
; 16 unsigned char and_m(unsigned char a, unsigned char *p) {
	ld (__a_2_and_m), hl
; 17     return a & *p;
	ld a, (__a_1_and_m)
	and (hl)
	ret
or_m:
; 20 unsigned char or_m(unsigned char a, unsigned char *p) {
	ld (__a_2_or_m), hl
; 21     return a | *p;
	ld a, (__a_1_or_m)
	or (hl)
	ret
xor_m:
; 24 unsigned char xor_m(unsigned char a, unsigned char *p) {
	ld (__a_2_xor_m), hl
; 25     return a ^ *p;
	ld a, (__a_1_xor_m)
	xor (hl)
	ret
cmp_m:
; 28 int cmp_m(unsigned char a, unsigned char *p) {
	ld (__a_2_cmp_m), hl
; 29     return a == *p;
	ld a, (__a_1_cmp_m)
	cp (hl)
	jp nz, l_0
	ld a, 1
	jp l_1
l_0:
	xor a
l_1:
	ld l, a
	ld h, 0
	ret
store_imm:
; 32 void store_imm(unsigned char *p) {
	ld (__a_1_store_imm), hl
; 33     *p = 0x42;
	ld (hl), 66
	ret
inc_m:
; 36 void inc_m(unsigned char *p) {
	ld (__a_1_inc_m), hl
; 37     (*p)++;
	ld a, (hl)
	inc a
	ld (hl), a
	ret
dec_m:
; 40 void dec_m(unsigned char *p) {
	ld (__a_1_dec_m), hl
; 41     (*p)--;
	ld a, (hl)
	dec a
	ld (hl), a
	ret
sum_bytes:
; 44 unsigned char sum_bytes(unsigned char *p, unsigned char n) {
	ld (__a_2_sum_bytes), a
; 45     unsigned char s = 0;
	xor a
	ld (sum_bytes_s), a
; 46     unsigned char i;
; 47     for (i = 0; i < n; ++i) s += p[i];
	ld (sum_bytes_i), a
l_2:
	ld hl, __a_2_sum_bytes
	cp (hl)
	jp nc, l_4
	ld hl, (__a_1_sum_bytes)
	ex hl, de
	ld hl, (sum_bytes_i)
	ld h, 0
	add hl, de
	ld a, (sum_bytes_s)
	add (hl)
	ld (sum_bytes_s), a
	ld a, (sum_bytes_i)
	inc a
	ld (sum_bytes_i), a
	jp l_2
l_4:
; 48     return s;
	ld a, (sum_bytes_s)
	ret
buf:
	db 1
	db 2
	db 3
	db 4
__bss:
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 5
__a_1_main equ __s_main + 1
__a_2_main equ __s_main + 3
main_a equ __s_main + 0
__s_add_m equ __static_stack + 0
__a_1_add_m equ __s_add_m + 0
__a_2_add_m equ __s_add_m + 1
__s_sub_m equ __static_stack + 0
__a_1_sub_m equ __s_sub_m + 0
__a_2_sub_m equ __s_sub_m + 1
__s_and_m equ __static_stack + 0
__a_1_and_m equ __s_and_m + 0
__a_2_and_m equ __s_and_m + 1
__s_or_m equ __static_stack + 0
__a_1_or_m equ __s_or_m + 0
__a_2_or_m equ __s_or_m + 1
__s_xor_m equ __static_stack + 0
__a_1_xor_m equ __s_xor_m + 0
__a_2_xor_m equ __s_xor_m + 1
__s_cmp_m equ __static_stack + 0
__a_1_cmp_m equ __s_cmp_m + 0
__a_2_cmp_m equ __s_cmp_m + 1
__s_store_imm equ __static_stack + 0
__a_1_store_imm equ __s_store_imm + 0
__s_inc_m equ __static_stack + 0
__a_1_inc_m equ __s_inc_m + 0
__s_dec_m equ __static_stack + 0
__a_1_dec_m equ __s_dec_m + 0
__s_sum_bytes equ __static_stack + 0
__a_1_sum_bytes equ __s_sum_bytes + 2
__a_2_sum_bytes equ __s_sum_bytes + 4
sum_bytes_s equ __s_sum_bytes + 0
sum_bytes_i equ __s_sum_bytes + 1
    savebin "tests\features\41\c8080.bin", __begin, __bss - __begin
