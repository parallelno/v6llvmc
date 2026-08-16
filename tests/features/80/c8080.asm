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
; 18     return static_probe(0x1122) + dynamic_probe(0x3344);
	ld hl, 4386
	call static_probe
	push hl
	ld hl, 13124
	call dynamic_probe
	pop de
	add hl, de
	ret
static_probe:
; 3 int static_probe(int parameter) {
	ld (__a_1_static_probe), hl
; 4     int local = parameter + 0x123;
	ld de, 291
	add hl, de
	ld (static_probe_local), hl
; 5     volatile int addressable = local + 1;
	inc hl
	ld (static_probe_addressable), hl
; 6     sink = addressable;
	ld (sink), hl
; 7     return local;
	ld hl, (static_probe_local)
	ret
dynamic_probe:
; 10 int dynamic_probe(int parameter) {
	ld (__a_1_dynamic_probe), hl
; 11     int local = parameter + 0x234;
	ld de, 564
	add hl, de
	ld (dynamic_probe_local), hl
; 12     volatile int addressable = local + 1;
	inc hl
	ld (dynamic_probe_addressable), hl
; 13     sink = addressable;
	ld (sink), hl
; 14     return local;
	ld hl, (dynamic_probe_local)
	ret
__bss:
sink:
	ds 2
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_static_probe equ __static_stack + 0
__a_1_static_probe equ __s_static_probe + 4
__s_dynamic_probe equ __static_stack + 0
__a_1_dynamic_probe equ __s_dynamic_probe + 4
static_probe_local equ __s_static_probe + 0
static_probe_addressable equ __s_static_probe + 2
dynamic_probe_local equ __s_dynamic_probe + 0
dynamic_probe_addressable equ __s_dynamic_probe + 2
    savebin ".\tests\features\80\c8080.bin", __begin, __bss - __begin
