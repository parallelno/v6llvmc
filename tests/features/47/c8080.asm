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
; 17 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 18     (void)argc; (void)argv;
; 19     g_sink = worker(1, 2, 3);
	ld a, 1
	ld (__a_1_worker), a
	ld a, 2
	ld (__a_2_worker), a
	ld a, 3
	call worker
	ld (g_sink), hl
; 20     return 0;
	ld hl, 0
	ret
worker:
; 10 unsigned int worker(unsigned char a, unsigned char b, unsigned char c) {
	ld (__a_3_worker), a
; 11     unsigned char r1 = ext_fn(a, b);
	ld a, (__a_1_worker)
	ld (__a_1_ext_fn), a
	ld a, (__a_2_worker)
	call ext_fn
	ld (worker_r1), a
; 12     unsigned char r2 = ext_fn(b, c);
	ld a, (__a_2_worker)
	ld (__a_1_ext_fn), a
	ld a, (__a_3_worker)
	call ext_fn
	ld (worker_r2), a
; 13     unsigned char r3 = ext_fn(a, c);
	ld a, (__a_1_worker)
	ld (__a_1_ext_fn), a
	ld a, (__a_3_worker)
	call ext_fn
	ld (worker_r3), a
; 14     return (unsigned int)r1 + r2 + r3;
	ld hl, (worker_r1)
	ld h, 0
	ex hl, de
	ld hl, (worker_r2)
	ld h, 0
	add hl, de
	ex hl, de
	ld hl, (worker_r3)
	ld h, 0
	add hl, de
	ret
__bss:
g_sink:
	ds 2
__static_stack:
	ds 12
__end:
__s___init equ __static_stack + 12
__s_main equ __static_stack + 8
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_worker equ __static_stack + 2
__a_1_worker equ __s_worker + 3
__a_2_worker equ __s_worker + 4
__a_3_worker equ __s_worker + 5
worker_r1 equ __s_worker + 0
__s_ext_fn equ __static_stack + 0
__a_1_ext_fn equ __s_ext_fn + 0
__a_2_ext_fn equ __s_ext_fn + 1
worker_r2 equ __s_worker + 1
worker_r3 equ __s_worker + 2
    savebin "tests\features\47\c8080.bin", __begin, __bss - __begin
