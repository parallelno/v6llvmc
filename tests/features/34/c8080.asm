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
; 16 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 17     hl_to_de(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_hl_to_de), hl
	ld hl, 22136
	call hl_to_de
; 18     return 0;
	ld hl, 0
	ret
hl_to_de:
; 10 void hl_to_de(unsigned int p, unsigned int y) {
	ld (__a_2_hl_to_de), hl
; 11     unsigned int v = op_hl(y);
	call op_hl
	ld (hl_to_de_v), hl
; 12     use_de(v, p);
	ld (__a_1_use_de), hl
	ld hl, (__a_1_hl_to_de)
	call use_de
; 13     g_after = v;
	ld hl, (hl_to_de_v)
	ld (g_after), hl
	ret
op_hl:
; 5 unsigned int op_hl(unsigned int x) { g_acc ^= x; return x + 1; }
	ld (__a_1_op_hl), hl
	ld hl, (g_acc)
	ex hl, de
	ld hl, (__a_1_op_hl)
	call __o_xor_16
	ld (g_acc), hl
	ld hl, (__a_1_op_hl)
	inc hl
	ret
use_de:
; 6 void use_de(unsigned int v, unsigned int p) { g_acc ^= v + p; }
	ld (__a_2_use_de), hl
	ld hl, (__a_1_use_de)
	ex hl, de
	ld hl, (__a_2_use_de)
	add hl, de
	ex hl, de
	ld hl, (g_acc)
	call __o_xor_16
	ld (g_acc), hl
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
g_acc:
	ds 2
g_after:
	ds 2
__static_stack:
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 10
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_hl_to_de equ __static_stack + 4
__a_1_hl_to_de equ __s_hl_to_de + 2
__a_2_hl_to_de equ __s_hl_to_de + 4
hl_to_de_v equ __s_hl_to_de + 0
__s_op_hl equ __static_stack + 0
__a_1_op_hl equ __s_op_hl + 0
__s_use_de equ __static_stack + 0
__a_1_use_de equ __s_use_de + 0
__a_2_use_de equ __s_use_de + 2
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\34\c8080.bin", __begin, __bss - __begin
