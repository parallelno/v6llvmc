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
; 52 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 53     cb_eq(0);
	xor a
	call cb_eq
; 54     cb_ne(1);
	ld a, 1
	call cb_ne
; 55     cb_ult(50);
	ld hl, 50
	call cb_ult
; 56     cb_uge(200);
	ld hl, 200
	call cb_uge
; 57     cb_slt(-1);
	ld hl, 65535
	call cb_slt
; 58     cb_sge(0);
	ld hl, 0
	call cb_sge
; 59     return cb_value_used(5) + observed;
	ld a, 5
	call cb_value_used
	ld e, a
	ld d, 0
	ld hl, (observed)
	ld h, 0
	add hl, de
	ret
cb_eq:
; 8 unsigned char cb_eq(unsigned char x) {
	ld (__a_1_cb_eq), a
; 9     if (x == 0) notify();
	or a
	call z, notify
; 10     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_ne:
; 13 unsigned char cb_ne(unsigned char x) {
	ld (__a_1_cb_ne), a
; 14     if (x != 0) notify();
	or a
	call nz, notify
; 15     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_ult:
; 18 unsigned char cb_ult(unsigned int x) {
	ld (__a_1_cb_ult), hl
; 19     if (x < 100) notify();
	ld de, 65436
	add hl, de
	call nc, notify
; 20     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_uge:
; 23 unsigned char cb_uge(unsigned int x) {
	ld (__a_1_cb_uge), hl
; 24     if (x >= 100) notify();
	ld de, 65436
	add hl, de
	call c, notify
; 25     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_slt:
; 28 unsigned char cb_slt(int x) {
	ld (__a_1_cb_slt), hl
; 29     if (x < 0) notify();
	ld de, 0
	call __o_sub_16
	call m, notify
; 30     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_sge:
; 33 unsigned char cb_sge(int x) {
	ld (__a_1_cb_sge), hl
; 34     if (x >= 0) notify();
	ld de, 0
	call __o_sub_16
	call p, notify
; 35     return observed + 1;
	ld a, (observed)
	inc a
	ret
cb_value_used:
; 40 unsigned char cb_value_used(unsigned char x) {
	ld (__a_1_cb_value_used), a
; 41     unsigned char v;
; 42     v = 7;
	ld a, 7
	ld (cb_value_used_v), a
; 43     if (x) v = produce();
	ld a, (__a_1_cb_value_used)
	or a
	jp z, l_12
	call produce
	ld (cb_value_used_v), a
l_12:
; 44     return v + observed;
	ld hl, cb_value_used_v
	ld a, (observed)
	add (hl)
	ret
notify:
; 49 void notify(void) { observed += 1; }
	ld a, (observed)
	inc a
	ld (observed), a
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
produce:
; 50 unsigned char produce(void) { return observed + 5; }
	ld a, (observed)
	add 5
	ret
__bss:
observed:
	ds 1
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 2
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_cb_eq equ __static_stack + 0
__a_1_cb_eq equ __s_cb_eq + 0
__s_cb_ne equ __static_stack + 0
__a_1_cb_ne equ __s_cb_ne + 0
__s_cb_ult equ __static_stack + 0
__a_1_cb_ult equ __s_cb_ult + 0
__s_cb_uge equ __static_stack + 0
__a_1_cb_uge equ __s_cb_uge + 0
__s_cb_slt equ __static_stack + 0
__a_1_cb_slt equ __s_cb_slt + 0
__s_cb_sge equ __static_stack + 0
__a_1_cb_sge equ __s_cb_sge + 0
__s_cb_value_used equ __static_stack + 0
__a_1_cb_value_used equ __s_cb_value_used + 1
cb_value_used_v equ __s_cb_value_used + 0
__s_notify equ __static_stack + 0
__s___o_sub_16 equ __static_stack + 0
__s_produce equ __static_stack + 0
    savebin "tests\features\49\c8080.bin", __begin, __bss - __begin
