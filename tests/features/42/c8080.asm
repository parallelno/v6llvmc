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
; 78 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 79     xor_bytes(0x11, 0x22, 0x33, 0x44, 0x55);
	ld a, 17
	ld (__a_1_xor_bytes), a
	ld a, 34
	ld (__a_2_xor_bytes), a
	ld a, 51
	ld (__a_3_xor_bytes), a
	ld a, 68
	ld (__a_4_xor_bytes), a
	ld a, 85
	call xor_bytes
; 80     and_bytes(0xF0, 0x0F, 0xAA);
	ld a, 240
	ld (__a_1_and_bytes), a
	ld a, 15
	ld (__a_2_and_bytes), a
	ld a, 170
	call and_bytes
; 81     or_bytes(0x01, 0x02, 0x04);
	ld a, 1
	ld (__a_1_or_bytes), a
	ld a, 2
	ld (__a_2_or_bytes), a
	ld a, 4
	call or_bytes
; 82     add_bytes(0x10, 0x20, 0x30);
	ld a, 16
	ld (__a_1_add_bytes), a
	ld a, 32
	ld (__a_2_add_bytes), a
	ld a, 48
	call add_bytes
; 83     xor_with_passthrough(0xA1, 0xB2, 0xC3, 0xD4);
	ld a, 161
	ld (__a_1_xor_with_passthrough), a
	ld a, 178
	ld (__a_2_xor_with_passthrough), a
	ld a, 195
	ld (__a_3_xor_with_passthrough), a
	ld a, 212
	call xor_with_passthrough
; 84     inc_via_ptr(&counter);
	ld hl, counter
	call inc_via_ptr
; 85     dec_via_ptr(&counter);
	ld hl, counter
	call dec_via_ptr
; 86     set_via_ptr(&flag);
	ld hl, flag
	call set_via_ptr
; 87     inc_volatile((volatile unsigned char *)&counter);
	ld hl, counter
	call inc_volatile
; 88     dec_volatile((volatile unsigned char *)&counter);
	ld hl, counter
	call dec_volatile
; 89     set_volatile((volatile unsigned char *)&flag);
	ld hl, flag
	call set_volatile
; 90     inc_indexed(&slot, 0);
	ld hl, slot
	ld (__a_1_inc_indexed), hl
	xor a
	call inc_indexed
; 91     set_indexed(&slot, 1);
	ld hl, slot
	ld (__a_1_set_indexed), hl
	ld a, 1
	call set_indexed
; 92     init_buf(&slot);
	ld hl, slot
	call init_buf
; 93     (void)inc_via_ptr_and_read(&counter);
	ld hl, counter
	call inc_via_ptr_and_read
; 94     return 0;
	ld hl, 0
	ret
xor_bytes:
; 11 unsigned char xor_bytes(unsigned char a, unsigned char b, unsigned char c,
	ld (__a_5_xor_bytes), a
; 12                         unsigned char d, unsigned char e) {
; 13     unsigned char x1 = op(a);
	ld a, (__a_1_xor_bytes)
	call op
	ld (xor_bytes_x1), a
; 14     unsigned char x2 = op(b);
	ld a, (__a_2_xor_bytes)
	call op
	ld (xor_bytes_x2), a
; 15     unsigned char x3 = op(c);
	ld a, (__a_3_xor_bytes)
	call op
	ld (xor_bytes_x3), a
; 16     unsigned char x4 = op(d);
	ld a, (__a_4_xor_bytes)
	call op
	ld (xor_bytes_x4), a
; 17     unsigned char x5 = op(e);
	ld a, (__a_5_xor_bytes)
	call op
	ld (xor_bytes_x5), a
; 18     use1(x1);
	ld a, (xor_bytes_x1)
	call use1
; 19     return (unsigned char)(x1 ^ x2 ^ x3 ^ x4 ^ x5);
	ld hl, xor_bytes_x1
	ld a, (xor_bytes_x2)
	xor (hl)
	ld hl, xor_bytes_x3
	xor (hl)
	ld hl, xor_bytes_x4
	xor (hl)
	ld hl, xor_bytes_x5
	xor (hl)
	ret
and_bytes:
; 22 unsigned char and_bytes(unsigned char a, unsigned char b, unsigned char c) {
	ld (__a_3_and_bytes), a
; 23     unsigned char x1 = op(a);
	ld a, (__a_1_and_bytes)
	call op
	ld (and_bytes_x1), a
; 24     unsigned char x2 = op(b);
	ld a, (__a_2_and_bytes)
	call op
	ld (and_bytes_x2), a
; 25     unsigned char x3 = op(c);
	ld a, (__a_3_and_bytes)
	call op
	ld (and_bytes_x3), a
; 26     use1(x1);
	ld a, (and_bytes_x1)
	call use1
; 27     return (unsigned char)(x1 & x2 & x3);
	ld hl, and_bytes_x1
	ld a, (and_bytes_x2)
	and (hl)
	ld hl, and_bytes_x3
	and (hl)
	ret
or_bytes:
; 30 unsigned char or_bytes(unsigned char a, unsigned char b, unsigned char c) {
	ld (__a_3_or_bytes), a
; 31     unsigned char x1 = op(a);
	ld a, (__a_1_or_bytes)
	call op
	ld (or_bytes_x1), a
; 32     unsigned char x2 = op(b);
	ld a, (__a_2_or_bytes)
	call op
	ld (or_bytes_x2), a
; 33     unsigned char x3 = op(c);
	ld a, (__a_3_or_bytes)
	call op
	ld (or_bytes_x3), a
; 34     use1(x1);
	ld a, (or_bytes_x1)
	call use1
; 35     return (unsigned char)(x1 | x2 | x3);
	ld hl, or_bytes_x1
	ld a, (or_bytes_x2)
	or (hl)
	ld hl, or_bytes_x3
	or (hl)
	ret
add_bytes:
; 38 unsigned char add_bytes(unsigned char a, unsigned char b, unsigned char c) {
	ld (__a_3_add_bytes), a
; 39     unsigned char x1 = op(a);
	ld a, (__a_1_add_bytes)
	call op
	ld (add_bytes_x1), a
; 40     unsigned char x2 = op(b);
	ld a, (__a_2_add_bytes)
	call op
	ld (add_bytes_x2), a
; 41     unsigned char x3 = op(c);
	ld a, (__a_3_add_bytes)
	call op
	ld (add_bytes_x3), a
; 42     use1(x1);
	ld a, (add_bytes_x1)
	call use1
; 43     return (unsigned char)(x1 + x2 + x3);
	ld hl, add_bytes_x1
	ld a, (add_bytes_x2)
	add (hl)
	ld hl, add_bytes_x3
	add (hl)
	ret
xor_with_passthrough:
; 46 unsigned char xor_with_passthrough(unsigned char a, unsigned char b,
	ld (__a_4_xor_with_passthrough), a
; 47                                    unsigned char c, unsigned char d) {
; 48     unsigned char x1 = op(a);
	ld a, (__a_1_xor_with_passthrough)
	call op
	ld (xor_with_passthrough_x1), a
; 49     unsigned char x2 = op(b);
	ld a, (__a_2_xor_with_passthrough)
	call op
	ld (xor_with_passthrough_x2), a
; 50     unsigned char x3 = op(c);
	ld a, (__a_3_xor_with_passthrough)
	call op
	ld (xor_with_passthrough_x3), a
; 51     unsigned char x4 = op(d);
	ld a, (__a_4_xor_with_passthrough)
	call op
	ld (xor_with_passthrough_x4), a
; 52     use2(x1, x2);
	ld a, (xor_with_passthrough_x1)
	ld (__a_1_use2), a
	ld a, (xor_with_passthrough_x2)
	call use2
; 53     return (unsigned char)((x1 ^ x2) ^ (x3 ^ x4));
	ld hl, xor_with_passthrough_x1
	ld a, (xor_with_passthrough_x2)
	xor (hl)
	ld d, a
	ld hl, xor_with_passthrough_x3
	ld a, (xor_with_passthrough_x4)
	xor (hl)
	xor d
	ret
inc_via_ptr:
; 56 void inc_via_ptr(unsigned char *p) { (*p)++; }
	ld (__a_1_inc_via_ptr), hl
	ld a, (hl)
	inc a
	ld (hl), a
	ret
dec_via_ptr:
; 57 void dec_via_ptr(unsigned char *p) { (*p)--; }
	ld (__a_1_dec_via_ptr), hl
	ld a, (hl)
	dec a
	ld (hl), a
	ret
set_via_ptr:
; 58 void set_via_ptr(unsigned char *p) { *p = 0x42; }
	ld (__a_1_set_via_ptr), hl
	ld (hl), 66
	ret
inc_volatile:
; 60 void inc_volatile(volatile unsigned char *p) { (*p)++; }
	ld (__a_1_inc_volatile), hl
	ld a, (hl)
	inc a
	ld (hl), a
	ret
dec_volatile:
; 61 void dec_volatile(volatile unsigned char *p) { (*p)--; }
	ld (__a_1_dec_volatile), hl
	ld a, (hl)
	dec a
	ld (hl), a
	ret
set_volatile:
; 62 void set_volatile(volatile unsigned char *p) { *p = 0x55; }
	ld (__a_1_set_volatile), hl
	ld (hl), 85
	ret
inc_indexed:
; 64 void inc_indexed(unsigned char *p, unsigned char i) { p[i]++; }
	ld (__a_2_inc_indexed), a
	ld hl, (__a_1_inc_indexed)
	ex hl, de
	ld hl, (__a_2_inc_indexed)
	ld h, 0
	add hl, de
	ld a, (hl)
	inc a
	ld hl, (__a_1_inc_indexed)
	ex hl, de
	ld hl, (__a_2_inc_indexed)
	ld h, 0
	add hl, de
	ld (hl), a
	ret
set_indexed:
; 65 void set_indexed(unsigned char *p, unsigned char i) { p[i] = 0x77; }
	ld (__a_2_set_indexed), a
	ld hl, (__a_1_set_indexed)
	ex hl, de
	ld hl, (__a_2_set_indexed)
	ld h, 0
	add hl, de
	ld (hl), 119
	ret
init_buf:
; 67 void init_buf(unsigned char *p) {
	ld (__a_1_init_buf), hl
; 68     p[0] = 0;
	xor a
	ld (hl), a
; 69     p[1] = 1;
	inc hl
	ld (hl), 1
; 70     p[2] = 0xFF;
	ld hl, (__a_1_init_buf)
	inc hl
	inc hl
	ld (hl), 255
	ret
inc_via_ptr_and_read:
; 73 unsigned char inc_via_ptr_and_read(unsigned char *p) {
	ld (__a_1_inc_via_ptr_and_read), hl
; 74     (*p)++;
	ld a, (hl)
	inc a
	ld (hl), a
; 75     return *p;
	ld a, (hl)
	ret
__bss:
counter:
	ds 1
flag:
	ds 1
slot:
	ds 1
__static_stack:
	ds 15
__end:
__s___init equ __static_stack + 15
__s_main equ __static_stack + 11
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_xor_bytes equ __static_stack + 1
__a_1_xor_bytes equ __s_xor_bytes + 5
__a_2_xor_bytes equ __s_xor_bytes + 6
__a_3_xor_bytes equ __s_xor_bytes + 7
__a_4_xor_bytes equ __s_xor_bytes + 8
__a_5_xor_bytes equ __s_xor_bytes + 9
__s_and_bytes equ __static_stack + 1
__a_1_and_bytes equ __s_and_bytes + 3
__a_2_and_bytes equ __s_and_bytes + 4
__a_3_and_bytes equ __s_and_bytes + 5
__s_or_bytes equ __static_stack + 1
__a_1_or_bytes equ __s_or_bytes + 3
__a_2_or_bytes equ __s_or_bytes + 4
__a_3_or_bytes equ __s_or_bytes + 5
__s_add_bytes equ __static_stack + 1
__a_1_add_bytes equ __s_add_bytes + 3
__a_2_add_bytes equ __s_add_bytes + 4
__a_3_add_bytes equ __s_add_bytes + 5
__s_xor_with_passthrough equ __static_stack + 2
__a_1_xor_with_passthrough equ __s_xor_with_passthrough + 4
__a_2_xor_with_passthrough equ __s_xor_with_passthrough + 5
__a_3_xor_with_passthrough equ __s_xor_with_passthrough + 6
__a_4_xor_with_passthrough equ __s_xor_with_passthrough + 7
__s_inc_via_ptr equ __static_stack + 0
__a_1_inc_via_ptr equ __s_inc_via_ptr + 0
__s_dec_via_ptr equ __static_stack + 0
__a_1_dec_via_ptr equ __s_dec_via_ptr + 0
__s_set_via_ptr equ __static_stack + 0
__a_1_set_via_ptr equ __s_set_via_ptr + 0
__s_inc_volatile equ __static_stack + 0
__a_1_inc_volatile equ __s_inc_volatile + 0
__s_dec_volatile equ __static_stack + 0
__a_1_dec_volatile equ __s_dec_volatile + 0
__s_set_volatile equ __static_stack + 0
__a_1_set_volatile equ __s_set_volatile + 0
__s_inc_indexed equ __static_stack + 0
__a_1_inc_indexed equ __s_inc_indexed + 0
__a_2_inc_indexed equ __s_inc_indexed + 2
__s_set_indexed equ __static_stack + 0
__a_1_set_indexed equ __s_set_indexed + 0
__a_2_set_indexed equ __s_set_indexed + 2
__s_init_buf equ __static_stack + 0
__a_1_init_buf equ __s_init_buf + 0
__s_inc_via_ptr_and_read equ __static_stack + 0
__a_1_inc_via_ptr_and_read equ __s_inc_via_ptr_and_read + 0
xor_bytes_x1 equ __s_xor_bytes + 0
__s_op equ __static_stack + 0
__a_1_op equ __s_op + 0
xor_bytes_x2 equ __s_xor_bytes + 1
xor_bytes_x3 equ __s_xor_bytes + 2
xor_bytes_x4 equ __s_xor_bytes + 3
xor_bytes_x5 equ __s_xor_bytes + 4
__s_use1 equ __static_stack + 0
__a_1_use1 equ __s_use1 + 0
and_bytes_x1 equ __s_and_bytes + 0
and_bytes_x2 equ __s_and_bytes + 1
and_bytes_x3 equ __s_and_bytes + 2
or_bytes_x1 equ __s_or_bytes + 0
or_bytes_x2 equ __s_or_bytes + 1
or_bytes_x3 equ __s_or_bytes + 2
add_bytes_x1 equ __s_add_bytes + 0
add_bytes_x2 equ __s_add_bytes + 1
add_bytes_x3 equ __s_add_bytes + 2
xor_with_passthrough_x1 equ __s_xor_with_passthrough + 0
xor_with_passthrough_x2 equ __s_xor_with_passthrough + 1
xor_with_passthrough_x3 equ __s_xor_with_passthrough + 2
xor_with_passthrough_x4 equ __s_xor_with_passthrough + 3
__s_use2 equ __static_stack + 0
__a_1_use2 equ __s_use2 + 0
__a_2_use2 equ __s_use2 + 1
    savebin "tests\features\42\c8080.bin", __begin, __bss - __begin
