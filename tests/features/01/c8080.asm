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
; 20 int main(int argc, char** argv) {
	ld (__a_2_main), hl
; 21     wrapper(42);
	ld hl, 42
	call wrapper
; 22     void_wrapper();
	call void_wrapper
; 23     not_tail(10);
	ld hl, 10
	call not_tail
; 24     return 0;
	ld hl, 0
	ret
wrapper:
; 5 int wrapper(int x) {
	ld (__a_1_wrapper), hl
; 6     return helper(x);
	jp helper
void_wrapper:
; 10 void void_wrapper(void) {
; 11     void_func();
	jp void_func
not_tail:
; 15 int not_tail(int x) {
	ld (__a_1_not_tail), hl
; 16     int r = helper(x);
	call helper
	ld (not_tail_r), hl
; 17     return r + 1;
	inc hl
	ret
helper:
; 1 int helper(int x) { return x + 1; }
	ld (__a_1_helper), hl
	inc hl
	ret
void_func:
; 2 void void_func(void) { }
	ret
__bss:
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_wrapper equ __static_stack + 2
__a_1_wrapper equ __s_wrapper + 0
__s_not_tail equ __static_stack + 2
__a_1_not_tail equ __s_not_tail + 2
__s_helper equ __static_stack + 0
__a_1_helper equ __s_helper + 0
__s_void_wrapper equ __static_stack + 0
not_tail_r equ __s_not_tail + 0
__s_void_func equ __static_stack + 0
    savebin "tests\features\01\c8080.bin", __begin, __bss - __begin
