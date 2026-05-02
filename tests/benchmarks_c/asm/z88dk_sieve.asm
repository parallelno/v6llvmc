;* * * * *  Small-C/Plus z88dk * * * * *
;  Version: 23854-4d530b6eb7-20251002
;
;	Reconstructed for z80 Module Assembler
;
;	Module compile time: Fri May 01 15:07:38 2026


	C_LINE	0,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c"

	MODULE	C__Work_Programming_v6llvmc_tests_benchmarks_c_src_sieve_c


	INCLUDE "z80_crt0.hdr"


	EXTERN	saved_hl
	C_LINE	0,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\bench.h"
	C_LINE	26,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\bench.h"
	C_LINE	27,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\bench.h"
	C_LINE	55,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\bench.h"
	SECTION	code_compiler

; Function bench_finish flags 0x00000200 __smallc 
; void bench_finish(unsigned char checksum)
; parameter 'unsigned char checksum' at sp+2 size(1)
	C_LINE	55,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\bench.h::bench_finish::0::0"
._bench_finish
    pop  bc          ; ret addr -> BC
    pop  hl          ; checksum lo in L
    ld   a, l
    out  (0xED), a
    halt
	ret


	C_LINE	4,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::bench_finish::0::1"
	C_LINE	14,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::bench_finish::0::1"
	C_LINE	16,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::bench_finish::0::1"

; Function init_buf flags 0x00000200 __smallc 
; void init_buf()
	C_LINE	16,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::init_buf::0::1"
._init_buf
	dec	sp
	ld	hl,0	;const
	add	hl,sp
	ld	(hl),0
	jp	i_4	;EOS
.i_2
	ld	hl,0	;const
	add	hl,sp
	inc	(hl)
.i_4
	pop	hl
	push	hl
	ld	a,l
	sub	252
	jp	nc,i_3	;
	ld	hl,_buf
	ex	de,hl
	pop	hl
	push	hl
	ld	h,0
	add	hl,de
	ld	(hl),1
	jp	i_2	;EOS
.i_3
	ld	hl,_buf
	ld	(hl),0
	ld	hl,_buf+1
	ld	(hl),0
	ld	l,(hl)
	ld	h,0
	inc	sp
	ret


	C_LINE	23,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::init_buf::0::2"

; Function cross_off flags 0x00000200 __smallc 
; void cross_off(unsigned char p)
; parameter 'unsigned char p' at sp+2 size(1)
	C_LINE	23,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::cross_off::0::2"
._cross_off
	push	bc
	ld	hl,4	;const
	add	hl,sp
	ld	e,(hl)
	ld	d,0
	ld	hl,4	;const
	add	hl,sp
	ld	l,(hl)
	ld	h,0
	add	hl,de
	pop	bc
	push	hl
	jp	i_7	;EOS
.i_5
	pop	de
	push	de
	ld	hl,4	;const
	add	hl,sp
	ld	l,(hl)
	ld	h,0
	add	hl,de
	pop	bc
	push	hl
.i_7
	pop	hl
	push	hl
	ld	a,l
	sub	252
	ld	a,h
	sbc	0
	jp	nc,i_6	;
	pop	hl
	push	hl
	ld	bc,_buf
	push	bc
	pop	de
	add	hl,de
	ld	(hl),0
	jp	i_5	;EOS
.i_6
	pop	bc
	ret


	C_LINE	32,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::cross_off::0::4"

; Function count_set flags 0x00000200 __smallc 
; unsigned char u8count_set()
	C_LINE	32,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::count_set::0::4"
._count_set
	dec	sp
	pop	hl
	ld	l,0
	push	hl
	dec	sp
	ld	hl,0	;const
	add	hl,sp
	ld	(hl),0
	jp	i_10	;EOS
.i_8
	ld	hl,0	;const
	add	hl,sp
	inc	(hl)
.i_10
	pop	hl
	push	hl
	ld	a,l
	sub	252
	jp	nc,i_9	;
	ld	hl,_buf
	ex	de,hl
	pop	hl
	push	hl
	ld	h,0
	add	hl,de
	ld	a,(hl)
	and	a
	jp	z,i_11	;
	ld	hl,1	;const
	add	hl,sp
	push	hl
	ld	l,(hl)
	ld	h,0
	inc	hl
	pop	de
	ld	a,l
	ld	(de),a
	jp	i_8	;EOS
.i_9
	pop	hl
	push	hl
	ld	l,h
	ld	h,0
	pop	bc
	ret


	C_LINE	39,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::count_set::0::5"

; Function main flags 0x00000000 __stdc 
; int main(int argc, char * * argv)
; parameter 'int argc' at 2 size(2)
; parameter 'char * * argv' at 4 size(2)
	C_LINE	39,"C:\Work\Programming\v6llvmc\tests\benchmarks_c\src\sieve.c::main::0::6"
._main
	pop	bc
	pop	hl
	push	hl
	push	bc
	call	l_gint4sp	;
	dec	sp
	call	_init_buf
	ld	hl,0	;const
	add	hl,sp
	ld	(hl),2
	jp	i_14	;EOS
.i_12
	ld	hl,0	;const
	add	hl,sp
	inc	(hl)
.i_14
	pop	hl
	push	hl
	ld	a,l
	sub	16
	jp	nc,i_13	;
	ld	hl,_buf
	ex	de,hl
	pop	hl
	push	hl
	ld	h,0
	add	hl,de
	ld	a,(hl)
	and	a
	jp	z,i_15	;
	pop	hl
	push	hl
	ld	h,0
	push	hl
	call	_cross_off
	pop	bc
	jp	i_12	;EOS
.i_13
	call	_count_set
	push	hl
	call	_bench_finish
	pop	bc
	ld	hl,0	;const
	inc	sp
	ret


	SECTION	bss_compiler
	SECTION	code_compiler
; --- Start of Optimiser additions ---
	defc	i_11 = i_8
	defc	i_15 = i_12


; --- Start of Static Variables ---

	SECTION	bss_compiler
._buf	defs	252
	SECTION	code_compiler


; --- Start of Scope Defns ---

	GLOBAL	_bench_finish
	GLOBAL	_main


; --- End of Scope Defns ---


; --- End of Compilation ---
