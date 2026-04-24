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
; 22 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 23     use2_u16(de_bc_three(0x1111, 0x2222, 0x3333),
	ld hl, 4369
	ld (__a_1_de_bc_three), hl
	ld hl, 8738
	ld (__a_2_de_bc_three), hl
	ld hl, 13107
	call de_bc_three
	ld (__a_1_use2_u16), hl
; 24              de_one_reload(0x4444, 0x5555));
	ld hl, 17476
	ld (__a_1_de_one_reload), hl
	ld hl, 21845
	call de_one_reload
	call use2_u16
; 25     return 0;
	ld hl, 0
	ret
de_bc_three:
; 8 unsigned int de_bc_three(unsigned int x, unsigned int y, unsigned int z) {
	ld (__a_3_de_bc_three), hl
; 9     unsigned int a = op_u16(x);
	ld hl, (__a_1_de_bc_three)
	call op_u16
	ld (de_bc_three_a), hl
; 10     unsigned int b = op2_u16(y);
	ld hl, (__a_2_de_bc_three)
	call op2_u16
	ld (de_bc_three_b), hl
; 11     unsigned int c = op_u16(z);
	ld hl, (__a_3_de_bc_three)
	call op_u16
	ld (de_bc_three_c), hl
; 12     use3_u16(a, b, c);
	ld hl, (de_bc_three_a)
	ld (__a_1_use3_u16), hl
	ld hl, (de_bc_three_b)
	ld (__a_2_use3_u16), hl
	ld hl, (de_bc_three_c)
	call use3_u16
; 13     return (unsigned int)(a + b + c);
	ld hl, (de_bc_three_a)
	ex hl, de
	ld hl, (de_bc_three_b)
	add hl, de
	ex hl, de
	ld hl, (de_bc_three_c)
	add hl, de
	ret
de_one_reload:
; 16 unsigned int de_one_reload(unsigned int x, unsigned int y) {
	ld (__a_2_de_one_reload), hl
; 17     unsigned int a = op_u16(x);
	ld hl, (__a_1_de_one_reload)
	call op_u16
	ld (de_one_reload_a), hl
; 18     unsigned int b = op2_u16(y);
	ld hl, (__a_2_de_one_reload)
	call op2_u16
	ld (de_one_reload_b), hl
; 19     return (unsigned int)(a + b);
	ld hl, (de_one_reload_a)
	ex hl, de
	ld hl, (de_one_reload_b)
	add hl, de
	ret
__bss:
__static_stack:
	ds 26
__end:
__s___init equ __static_stack + 26
__s_main equ __static_stack + 22
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_de_bc_three equ __static_stack + 6
__a_1_de_bc_three equ __s_de_bc_three + 6
__a_2_de_bc_three equ __s_de_bc_three + 8
__a_3_de_bc_three equ __s_de_bc_three + 10
__s_de_one_reload equ __static_stack + 2
__a_1_de_one_reload equ __s_de_one_reload + 4
__a_2_de_one_reload equ __s_de_one_reload + 6
__s_use2_u16 equ __static_stack + 18
__a_1_use2_u16 equ __s_use2_u16 + 0
__a_2_use2_u16 equ __s_use2_u16 + 2
de_bc_three_a equ __s_de_bc_three + 0
__s_op_u16 equ __static_stack + 0
__a_1_op_u16 equ __s_op_u16 + 0
de_bc_three_b equ __s_de_bc_three + 2
__s_op2_u16 equ __static_stack + 0
__a_1_op2_u16 equ __s_op2_u16 + 0
de_bc_three_c equ __s_de_bc_three + 4
__s_use3_u16 equ __static_stack + 0
__a_1_use3_u16 equ __s_use3_u16 + 0
__a_2_use3_u16 equ __s_use3_u16 + 2
__a_3_use3_u16 equ __s_use3_u16 + 4
de_one_reload_a equ __s_de_one_reload + 0
de_one_reload_b equ __s_de_one_reload + 2
    savebin "tests\features\39\c8080.bin", __begin, __bss - __begin
