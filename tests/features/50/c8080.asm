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
; 30 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 31     (void)argc; (void)argv;
; 32     g_arr[0] = 1; g_arr[1] = 2; g_arr[2] = 3; g_arr[3] = 4;
	ld a, 1
	ld (g_arr), a
	ld a, 2
	ld (0FFFFh & ((g_arr) + (1))), a
	ld a, 3
	ld (0FFFFh & ((g_arr) + (2))), a
	ld a, 4
	ld (0FFFFh & ((g_arr) + (3))), a
; 33     unsigned char r1 = sum4_global();
	call sum4_global
	ld (main_r1), a
; 34     unsigned char r2 = sum4_array(g_arr);
	ld hl, g_arr
	call sum4_array
	ld (main_r2), a
; 35     write4_globals(r1 + r2);
	ld hl, main_r1
	add (hl)
	call write4_globals
; 36     return ext_sink(g_a + g_b + g_c + g_d);
	ld hl, g_a
	ld a, (g_b)
	add (hl)
	ld hl, g_c
	add (hl)
	ld hl, g_d
	add (hl)
	call ext_sink
	ld l, a
	ld h, 0
	ret
sum4_global:
; 8 unsigned char sum4_global(void) {
; 9     return g_s.x + g_s.y + g_s.z + g_s.w;
	ld hl, g_s
	ld a, (0FFFFh & ((g_s) + (1)))
	add (hl)
	ld hl, 0FFFFh & ((g_s) + (2))
	add (hl)
	ld hl, 0FFFFh & ((g_s) + (3))
	add (hl)
	ret
sum4_array:
; 20 unsigned char sum4_array(const unsigned char *p) {
	ld (__a_1_sum4_array), hl
; 21     unsigned char s = p[0];
	ld a, (hl)
; 22     s += p[1];
	inc hl
	add (hl)
; 23     s += p[2];
	ld hl, (__a_1_sum4_array)
	inc hl
	inc hl
	add (hl)
; 24     s += p[3];
	ld hl, (__a_1_sum4_array)
	inc hl
	inc hl
	inc hl
	add (hl)
	ld (sum4_array_s), a
; 25     return s;
	ret
write4_globals:
; 13 void write4_globals(unsigned char v) {
	ld (__a_1_write4_globals), a
; 14     g_a = v;
	ld (g_a), a
; 15     g_b = v + 1;
	ld a, (__a_1_write4_globals)
	inc a
	ld (g_b), a
; 16     g_c = v + 2;
	ld a, (__a_1_write4_globals)
	add 2
	ld (g_c), a
; 17     g_d = v + 3;
	ld a, (__a_1_write4_globals)
	add 3
	ld (g_d), a
	ret
__bss:
g_s:
	ds 4
g_a:
	ds 1
g_b:
	ds 1
g_c:
	ds 1
g_d:
	ds 1
g_arr:
	ds 4
__static_stack:
	ds 9
__end:
__s___init equ __static_stack + 9
__s_main equ __static_stack + 3
__a_1_main equ __s_main + 2
__a_2_main equ __s_main + 4
main_r1 equ __s_main + 0
main_r2 equ __s_main + 1
__s_sum4_array equ __static_stack + 0
__a_1_sum4_array equ __s_sum4_array + 1
__s_write4_globals equ __static_stack + 0
__a_1_write4_globals equ __s_write4_globals + 0
__s_ext_sink equ __static_stack + 0
__a_1_ext_sink equ __s_ext_sink + 0
__s_sum4_global equ __static_stack + 0
sum4_array_s equ __s_sum4_array + 0
    savebin "tests\features\50\c8080.bin", __begin, __bss - __begin
