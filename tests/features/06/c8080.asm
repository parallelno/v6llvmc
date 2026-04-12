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
; 19 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 20     write_port(42);
	ld a, 42
	call write_port
; 21     copy_port();
	call copy_port
; 22     unsigned char r = read_port();
	call read_port
	ld (main_r), a
; 23     return r;
	ld hl, (main_r)
	ld h, 0
	ret
write_port:
; 11 void write_port(unsigned char val) {
	ld (__a_1_write_port), a
; 12     PORT_A = val;
	ld (256), a
	ret
copy_port:
; 15 void copy_port(void) {
; 16     PORT_B = PORT_A;
	ld a, (256)
	ld (512), a
	ret
read_port:
; 7 unsigned char read_port(void) {
; 8     return PORT_A;
	ld a, (256)
	ret
__bss:
__static_stack:
	ds 6
__end:
__s___init equ __static_stack + 6
__s_main equ __static_stack + 1
__a_1_main equ __s_main + 1
__a_2_main equ __s_main + 3
__s_write_port equ __static_stack + 0
__a_1_write_port equ __s_write_port + 0
main_r equ __s_main + 0
__s_copy_port equ __static_stack + 0
__s_read_port equ __static_stack + 0
    savebin "tests\features\06\c8080.bin", __begin, __bss - __begin
