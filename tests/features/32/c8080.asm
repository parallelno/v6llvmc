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
; 23 int main(int argc, char **argv) {
	ld (__a_2_main), hl
; 24     u16_shl8 (0x1234, &u16_p, &u16_q);
	ld hl, 4660
	ld (__a_1_u16_shl8), hl
	ld hl, u16_p
	ld (__a_2_u16_shl8), hl
	ld hl, u16_q
	call u16_shl8
; 25     u16_shl10(0x1234, &u16_p, &u16_q);
	ld hl, 4660
	ld (__a_1_u16_shl10), hl
	ld hl, u16_p
	ld (__a_2_u16_shl10), hl
	ld hl, u16_q
	call u16_shl10
; 26     u16_srl8 (0x1234, &u16_p, &u16_q);
	ld hl, 4660
	ld (__a_1_u16_srl8), hl
	ld hl, u16_p
	ld (__a_2_u16_srl8), hl
	ld hl, u16_q
	call u16_srl8
; 27     u16_srl10(0x1234, &u16_p, &u16_q);
	ld hl, 4660
	ld (__a_1_u16_srl10), hl
	ld hl, u16_p
	ld (__a_2_u16_srl10), hl
	ld hl, u16_q
	call u16_srl10
; 28 
; 29     i16_sra8 (-1234,  &i16_p, &i16_q);
	ld hl, 64302
	ld (__a_1_i16_sra8), hl
	ld hl, i16_p
	ld (__a_2_i16_sra8), hl
	ld hl, i16_q
	call i16_sra8
; 30     i16_sra10(-1234,  &i16_p, &i16_q);
	ld hl, 64302
	ld (__a_1_i16_sra10), hl
	ld hl, i16_p
	ld (__a_2_i16_sra10), hl
	ld hl, i16_q
	call i16_sra10
; 31 
; 32     u8_shl3(0x12, &u8_p, &u8_q);
	ld a, 18
	ld (__a_1_u8_shl3), a
	ld hl, u8_p
	ld (__a_2_u8_shl3), hl
	ld hl, u8_q
	call u8_shl3
; 33     i8_shl3(0x12, &i8_p, &i8_q);
	ld a, 18
	ld (__a_1_i8_shl3), a
	ld hl, i8_p
	ld (__a_2_i8_shl3), hl
	ld hl, i8_q
	call i8_shl3
; 34     return 0;
	ld hl, 0
	ret
u16_shl8:
; 3 void u16_shl8 (unsigned int  x, unsigned int  *p, unsigned int  *q) { *p = x; *q = x << 8;  }
	ld (__a_3_u16_shl8), hl
	ld hl, (__a_1_u16_shl8)
	ex hl, de
	ld hl, (__a_2_u16_shl8)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_u16_shl8)
	ld h, l
	ld l, 0
	ex hl, de
	ld hl, (__a_3_u16_shl8)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
u16_shl10:
; 4 void u16_shl10(unsigned int  x, unsigned int  *p, unsigned int  *q) { *p = x; *q = x << 10; }
	ld (__a_3_u16_shl10), hl
	ld hl, (__a_1_u16_shl10)
	ex hl, de
	ld hl, (__a_2_u16_shl10)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_u16_shl10)
	ld h, l
	ld l, 0
	add hl, hl
	add hl, hl
	ex hl, de
	ld hl, (__a_3_u16_shl10)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
u16_srl8:
; 5 void u16_srl8 (unsigned int  x, unsigned int  *p, unsigned int  *q) { *p = x; *q = x >> 8;  }
	ld (__a_3_u16_srl8), hl
	ld hl, (__a_1_u16_srl8)
	ex hl, de
	ld hl, (__a_2_u16_srl8)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_u16_srl8)
	ld l, h
	ld h, 0
	ex hl, de
	ld hl, (__a_3_u16_srl8)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
u16_srl10:
; 6 void u16_srl10(unsigned int  x, unsigned int  *p, unsigned int  *q) { *p = x; *q = x >> 10; }
	ld (__a_3_u16_srl10), hl
	ld hl, (__a_1_u16_srl10)
	ex hl, de
	ld hl, (__a_2_u16_srl10)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_u16_srl10)
	ld de, 10
	call __o_shr_u16
	ex hl, de
	ld hl, (__a_3_u16_srl10)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
i16_sra8:
; 12 void i16_sra8 (         int  x,          int  *p,          int  *q) { *p = x; *q = x >> 8;  }
	ld (__a_3_i16_sra8), hl
	ld hl, (__a_1_i16_sra8)
	ex hl, de
	ld hl, (__a_2_i16_sra8)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_i16_sra8)
	ld de, 8
	call __o_shr_i16
	ex hl, de
	ld hl, (__a_3_i16_sra8)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
i16_sra10:
; 13 void i16_sra10(         int  x,          int  *p,          int  *q) { *p = x; *q = x >> 10; }
	ld (__a_3_i16_sra10), hl
	ld hl, (__a_1_i16_sra10)
	ex hl, de
	ld hl, (__a_2_i16_sra10)
	ld (hl), e
	inc hl
	ld (hl), d
	ld hl, (__a_1_i16_sra10)
	ld de, 10
	call __o_shr_i16
	ex hl, de
	ld hl, (__a_3_i16_sra10)
	ld (hl), e
	inc hl
	ld (hl), d
	ret
u8_shl3:
; 15 void u8_shl3(unsigned char x, unsigned char *p, unsigned char *q) { *p = x; *q = x << 3; }
	ld (__a_3_u8_shl3), hl
	ld hl, (__a_2_u8_shl3)
	ld a, (__a_1_u8_shl3)
	ld (hl), a
	ld hl, (__a_3_u8_shl3)
	add a
	add a
	add a
	ld (hl), a
	ret
i8_shl3:
; 16 void i8_shl3(  signed char x,   signed char *p,   signed char *q) { *p = x; *q = x << 3; }
	ld (__a_3_i8_shl3), hl
	ld hl, (__a_2_i8_shl3)
	ld a, (__a_1_i8_shl3)
	ld (hl), a
	ld d, 3
	call __o_shl_8
	ld hl, (__a_3_i8_shl3)
	ld (hl), a
	ret
__o_shr_u16:
; 521 void __o_shr_u16() {
; 522     asm {

        inc  e
__o_shr_u16__l1:
        dec  e
        ret  z
        ld   a, h
        or   a    ; cf = 0
        rra
        ld   h, a
        ld   a, l
        rra
        ld   l, a
        jp   __o_shr_u16__l1
1

	ret
__o_shr_i16:
; 543 void __o_shr_i16() {
; 544     asm {

        inc  e
__o_shr_i16__l1:
        dec  e
        ret  z
        ld   a, h
        rla
        ld   a, h
        rra
        ld   h, a
        ld   a, l
        rra
        ld   l, a
        jp   __o_shr_i16__l1

	ret
__o_shl_8:
; 89 void __o_shl_8() {
; 90     asm {

        inc  d
__o_shl_8__l1:
        dec  d
        ret  z
        add  a
        jp   __o_shl_8__l1

	ret
__bss:
u16_p:
	ds 2
u16_q:
	ds 2
i16_p:
	ds 2
i16_q:
	ds 2
u8_p:
	ds 1
u8_q:
	ds 1
i8_p:
	ds 1
i8_q:
	ds 1
__static_stack:
	ds 10
__end:
__s___init equ __static_stack + 10
__s_main equ __static_stack + 6
__a_1_main equ __s_main + 0
__a_2_main equ __s_main + 2
__s_u16_shl8 equ __static_stack + 0
__a_1_u16_shl8 equ __s_u16_shl8 + 0
__a_2_u16_shl8 equ __s_u16_shl8 + 2
__a_3_u16_shl8 equ __s_u16_shl8 + 4
__s_u16_shl10 equ __static_stack + 0
__a_1_u16_shl10 equ __s_u16_shl10 + 0
__a_2_u16_shl10 equ __s_u16_shl10 + 2
__a_3_u16_shl10 equ __s_u16_shl10 + 4
__s_u16_srl8 equ __static_stack + 0
__a_1_u16_srl8 equ __s_u16_srl8 + 0
__a_2_u16_srl8 equ __s_u16_srl8 + 2
__a_3_u16_srl8 equ __s_u16_srl8 + 4
__s_u16_srl10 equ __static_stack + 0
__a_1_u16_srl10 equ __s_u16_srl10 + 0
__a_2_u16_srl10 equ __s_u16_srl10 + 2
__a_3_u16_srl10 equ __s_u16_srl10 + 4
__s_i16_sra8 equ __static_stack + 0
__a_1_i16_sra8 equ __s_i16_sra8 + 0
__a_2_i16_sra8 equ __s_i16_sra8 + 2
__a_3_i16_sra8 equ __s_i16_sra8 + 4
__s_i16_sra10 equ __static_stack + 0
__a_1_i16_sra10 equ __s_i16_sra10 + 0
__a_2_i16_sra10 equ __s_i16_sra10 + 2
__a_3_i16_sra10 equ __s_i16_sra10 + 4
__s_u8_shl3 equ __static_stack + 0
__a_1_u8_shl3 equ __s_u8_shl3 + 0
__a_2_u8_shl3 equ __s_u8_shl3 + 1
__a_3_u8_shl3 equ __s_u8_shl3 + 3
__s_i8_shl3 equ __static_stack + 0
__a_1_i8_shl3 equ __s_i8_shl3 + 0
__a_2_i8_shl3 equ __s_i8_shl3 + 1
__a_3_i8_shl3 equ __s_i8_shl3 + 3
__s___o_shr_u16 equ __static_stack + 0
__s___o_shr_i16 equ __static_stack + 0
__s___o_shl_8 equ __static_stack + 0
    savebin "tests\features\32\c8080.bin", __begin, __bss - __begin
