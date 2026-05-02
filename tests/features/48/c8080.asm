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
; 36 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 37     (void)argc; (void)argv;
; 38     g8 = load8_stack_arg(1, 2, 3, 4, 5, 6, 7, 8);
	ld a, 1
	ld (__a_1_load8_stack_arg), a
	ld a, 2
	ld (__a_2_load8_stack_arg), a
	ld a, 3
	ld (__a_3_load8_stack_arg), a
	ld a, 4
	ld (__a_4_load8_stack_arg), a
	ld a, 5
	ld (__a_5_load8_stack_arg), a
	ld a, 6
	ld (__a_6_load8_stack_arg), a
	ld a, 7
	ld (__a_7_load8_stack_arg), a
	ld a, 8
	call load8_stack_arg
	ld (g8), a
; 39     g16 = load16_stack_arg(1, 2, 3, 4);
	ld hl, 1
	ld (__a_1_load16_stack_arg), hl
	ld hl, 2
	ld (__a_2_load16_stack_arg), hl
	ld hl, 3
	ld (__a_3_load16_stack_arg), hl
	ld hl, 4
	call load16_stack_arg
	ld (g16), hl
; 40     g8 = store8_local(g8);
	ld a, (g8)
	call store8_local
	ld (g8), a
; 41     g16 = store16_local(g16);
	ld hl, (g16)
	call store16_local
	ld (g16), hl
; 42     return 0;
	ld hl, 0
	ret
load8_stack_arg:
; 12 u8 load8_stack_arg(u8 a0, u8 a1, u8 a2, u8 a3,
	ld (__a_8_load8_stack_arg), a
; 13                    u8 a4, u8 a5, u8 a6, u8 a7) {
; 14     return a7;
	ret
load16_stack_arg:
; 18 int load16_stack_arg(int a0, int a1, int a2, int a3) {
	ld (__a_4_load16_stack_arg), hl
; 19     return a0 + a1 + a2 + a3;
	ld hl, (__a_1_load16_stack_arg)
	ex hl, de
	ld hl, (__a_2_load16_stack_arg)
	add hl, de
	ex hl, de
	ld hl, (__a_3_load16_stack_arg)
	add hl, de
	ex hl, de
	ld hl, (__a_4_load16_stack_arg)
	add hl, de
	ret
store8_local:
; 23 u8 store8_local(u8 x) {
	ld (__a_1_store8_local), a
; 24     volatile u8 slot;
; 25     slot = x;
	ld (store8_local_slot), a
; 26     return slot;
	ret
store16_local:
; 30 int store16_local(int x) {
	ld (__a_1_store16_local), hl
; 31     volatile int slot;
; 32     slot = x;
	ld (store16_local_slot), hl
; 33     return slot;
	ret
__bss:
g8:
	ds 1
g16:
	ds 2
__static_stack:
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_load8_stack_arg equ __static_stack + 0
__a_1_load8_stack_arg equ __s_load8_stack_arg + 0
__a_2_load8_stack_arg equ __s_load8_stack_arg + 1
__a_3_load8_stack_arg equ __s_load8_stack_arg + 2
__a_4_load8_stack_arg equ __s_load8_stack_arg + 3
__a_5_load8_stack_arg equ __s_load8_stack_arg + 4
__a_6_load8_stack_arg equ __s_load8_stack_arg + 5
__a_7_load8_stack_arg equ __s_load8_stack_arg + 6
__a_8_load8_stack_arg equ __s_load8_stack_arg + 7
__s_load16_stack_arg equ __static_stack + 0
__a_1_load16_stack_arg equ __s_load16_stack_arg + 0
__a_2_load16_stack_arg equ __s_load16_stack_arg + 2
__a_3_load16_stack_arg equ __s_load16_stack_arg + 4
__a_4_load16_stack_arg equ __s_load16_stack_arg + 6
__s_store8_local equ __static_stack + 0
__a_1_store8_local equ __s_store8_local + 1
__s_store16_local equ __static_stack + 0
__a_1_store16_local equ __s_store16_local + 2
store8_local_slot equ __s_store8_local + 0
store16_local_slot equ __s_store16_local + 0
    savebin "tests\features\48\c8080.bin", __begin, __bss - __begin
