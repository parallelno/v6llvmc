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
; 27 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 28     g1 = de_one_reload(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_de_one_reload), hl
	ld hl, 22136
	call de_one_reload
	ld (g1), hl
; 29     g2 = mixed_hl_de(0xaaaa, 0xbbbb);
	ld hl, 43690
	ld (__a_1_mixed_hl_de), hl
	ld hl, 48059
	call mixed_hl_de
	ld (g2), hl
; 30     return 0;
	ld hl, 0
	ret
de_one_reload:
; 12 unsigned int de_one_reload(unsigned int x, unsigned int y) {
	ld (__a_2_de_one_reload), hl
; 13     unsigned int a = op1(x);
	ld hl, (__a_1_de_one_reload)
	call op1
	ld (de_one_reload_a), hl
; 14     unsigned int b = op2(y);
	ld hl, (__a_2_de_one_reload)
	call op2
	ld (de_one_reload_b), hl
; 15     return a + b;
	ld hl, (de_one_reload_a)
	ex hl, de
	ld hl, (de_one_reload_b)
	add hl, de
	ret
mixed_hl_de:
; 18 unsigned int mixed_hl_de(unsigned int x, unsigned int y) {
	ld (__a_2_mixed_hl_de), hl
; 19     unsigned int a = op1(x);
	ld hl, (__a_1_mixed_hl_de)
	call op1
	ld (mixed_hl_de_a), hl
; 20     unsigned int t1 = op2(a);
	call op2
	ld (mixed_hl_de_t1), hl
; 21     unsigned int t2 = op2(y);
	ld hl, (__a_2_mixed_hl_de)
	call op2
	ld (mixed_hl_de_t2), hl
; 22     return t1 + t2 + a;
	ld hl, (mixed_hl_de_t1)
	ex hl, de
	ld hl, (mixed_hl_de_t2)
	add hl, de
	ex hl, de
	ld hl, (mixed_hl_de_a)
	add hl, de
	ret
op1:
; 9 unsigned int op1(unsigned int x) { op_acc ^= x; return x + 1; }
	ld (__a_1_op1), hl
	ld hl, (op_acc)
	ex hl, de
	ld hl, (__a_1_op1)
	call __o_xor_16
	ld (op_acc), hl
	ld hl, (__a_1_op1)
	inc hl
	ret
op2:
; 10 unsigned int op2(unsigned int x) { op_acc ^= x; return x + 2; }
	ld (__a_1_op2), hl
	ld hl, (op_acc)
	ex hl, de
	ld hl, (__a_1_op2)
	call __o_xor_16
	ld (op_acc), hl
	ld hl, (__a_1_op2)
	inc hl
	inc hl
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
op_acc:
	ds 2
g1:
	ds 2
g2:
	ds 2
__static_stack:
	ds 16
__end:
__s___init equ __static_stack + 16
__s_main equ __static_stack + 12
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_de_one_reload equ __static_stack + 2
__a_1_de_one_reload equ __s_de_one_reload + 4
__a_2_de_one_reload equ __s_de_one_reload + 6
__s_mixed_hl_de equ __static_stack + 2
__a_1_mixed_hl_de equ __s_mixed_hl_de + 6
__a_2_mixed_hl_de equ __s_mixed_hl_de + 8
de_one_reload_a equ __s_de_one_reload + 0
__s_op1 equ __static_stack + 0
__a_1_op1 equ __s_op1 + 0
de_one_reload_b equ __s_de_one_reload + 2
__s_op2 equ __static_stack + 0
__a_1_op2 equ __s_op2 + 0
mixed_hl_de_a equ __s_mixed_hl_de + 0
mixed_hl_de_t1 equ __s_mixed_hl_de + 2
mixed_hl_de_t2 equ __s_mixed_hl_de + 4
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\35\c8080.bin", __begin, __bss - __begin
