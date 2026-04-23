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
; 28     g1 = hl_one_spill(0x1234, 0x5678);
	ld hl, 4660
	ld (__a_1_hl_one_spill), hl
	ld hl, 22136
	call hl_one_spill
	ld (g1), hl
; 29     g2 = hl_two_reloads(0xabcd);
	ld hl, 43981
	call hl_two_reloads
	ld (g2), hl
; 30     return 0;
	ld hl, 0
	ret
hl_one_spill:
; 12 unsigned int hl_one_spill(unsigned int x, unsigned int y) {
	ld (__a_2_hl_one_spill), hl
; 13     unsigned int a = op1(x);
	ld hl, (__a_1_hl_one_spill)
	call op1
	ld (hl_one_spill_a), hl
; 14     unsigned int b = op2(y);
	ld hl, (__a_2_hl_one_spill)
	call op2
	ld (hl_one_spill_b), hl
; 15     return a + b;
	ld hl, (hl_one_spill_a)
	ex hl, de
	ld hl, (hl_one_spill_b)
	add hl, de
	ret
hl_two_reloads:
; 18 unsigned int hl_two_reloads(unsigned int x) {
	ld (__a_1_hl_two_reloads), hl
; 19     unsigned int a = op1(x);
	call op1
	ld (hl_two_reloads_a), hl
; 20     unsigned int b1 = op2(a);
	call op2
	ld (hl_two_reloads_b1), hl
; 21     unsigned int b2 = op2(a);
	ld hl, (hl_two_reloads_a)
	call op2
	ld (hl_two_reloads_b2), hl
; 22     return b1 + b2;
	ld hl, (hl_two_reloads_b1)
	ex hl, de
	ld hl, (hl_two_reloads_b2)
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
	ds 14
__end:
__s___init equ __static_stack + 14
__s_main equ __static_stack + 10
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_hl_one_spill equ __static_stack + 2
__a_1_hl_one_spill equ __s_hl_one_spill + 4
__a_2_hl_one_spill equ __s_hl_one_spill + 6
__s_hl_two_reloads equ __static_stack + 2
__a_1_hl_two_reloads equ __s_hl_two_reloads + 6
hl_one_spill_a equ __s_hl_one_spill + 0
__s_op1 equ __static_stack + 0
__a_1_op1 equ __s_op1 + 0
hl_one_spill_b equ __s_hl_one_spill + 2
__s_op2 equ __static_stack + 0
__a_1_op2 equ __s_op2 + 0
hl_two_reloads_a equ __s_hl_two_reloads + 0
hl_two_reloads_b1 equ __s_hl_two_reloads + 2
hl_two_reloads_b2 equ __s_hl_two_reloads + 4
__s___o_xor_16 equ __static_stack + 0
    savebin "tests\features\33\c8080.bin", __begin, __bss - __begin
