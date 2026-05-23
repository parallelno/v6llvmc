	.text
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
	;=== void draw_pixel(char arg0, char arg1) ===
	;  arg0 = A
	;  arg1 = B
; %bb.0:
	MOV	H, A
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	D, L
	MOV	E, B
	;--- V6C_BUILD_PAIR ---
	MOV	B, L
	MOV	C, H
	;--- V6C_SRL16 ---
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	MOV	A, B
	ORA	A
	RAR
	MOV	B, A
	MOV	A, C
	RAR
	MOV	C, A
	;--- V6C_BUILD_PAIR ---
	MOV	B, C
	MOV	C, L
	;--- V6C_OR16 ---
	MOV	A, C
	ORA	E
	MOV	E, A
	MOV	A, B
	ORA	D
	MOV	D, A
	LXI	B, 0x8000
	;--- V6C_OR16 ---
	MOV	A, E
	ORA	C
	MOV	C, A
	MOV	A, D
	ORA	B
	MOV	B, A
	MOV	A, H
	CMA
	ANI	7
	;--- V6C_BUILD_PAIR ---
	MOV	D, L
	MOV	E, A
	LXI	H, 1
	CALL	__ashlhi3
	MOV	A, L
	;--- V6C_ORA_M_P ---
	MOV	L, C
	MOV	H, B
	ORA	M
	;--- V6C_STORE8_P ---
	STAX	B
	RET
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
	;=== void draw_line(char arg0, char arg1) ===
	;  arg0 = A
	;  arg1 = B
; %bb.0:
	;--- V6C_SPILL8 ---
	LXI	H, .LLo61_8+1
	MOV	M, B
	MVI	L, 0
	;--- V6C_BUILD_PAIR ---
	MOV	H, L
	MOV	L, A
	;--- V6C_SPILL8 ---
	STA	.LLo61_5+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNC	.LBB16_2
; %bb.1:
	LXI	D, 0x7f
	;--- V6C_XOR16 ---
	MOV	A, L
	XRA	E
	MOV	L, A
	MOV	A, H
	XRA	D
	MOV	H, A
	JMP	.LBB16_3
.LBB16_2:
	LXI	D, 0xff81
	;--- V6C_ADD16 ---
	DAD	D
.LBB16_3:
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_2+1
	XRA	A
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_8+1
	MOV	E, M
	;--- V6C_BUILD_PAIR ---
	MOV	H, A
	MOV	L, E
	MOV	A, E
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNC	.LBB16_5
; %bb.4:
	LXI	D, 0xff81
	;--- V6C_ADD16 ---
	DAD	D
	JMP	.LBB16_6
.LBB16_5:
	LXI	D, 0x7f
	;--- V6C_SUB16 ---
	MOV	A, E
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
.LBB16_6:
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_1+1
	MVI	A, 0x7f
	MOV	B, A
	CALL	draw_pixel
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_8+1
	;--- V6C_CMP8_ZERO ---
	ORA	A
	MVI	A, 1
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
	JM	.LBB16_8
; %bb.7:
	MVI	A, 0xff
	;--- V6C_SPILL8 ---
	STA	.LLo61_7+1
.LBB16_8:
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
	;--- V6C_CMP8_ZERO ---
	ORA	A
	JM	.LBB16_10
; %bb.9:
	MVI	A, 0xff
	;--- V6C_SPILL8 ---
	STA	.LLo61_4+1
.LBB16_10:
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_8+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	JNZ	.LBB16_12
; %bb.11:
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_5+1
	CPI	0x7f
	;--- V6C_BRCOND ---
	RZ
.LBB16_12:
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
	;--- V6C_RELOAD16 ---
	XCHG
	LHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	DAD	D
	MOV	B, H
	MOV	C, L
	MVI	A, 0x7f
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
.LBB16_13:                              ; =>This Inner Loop Header: Depth=1
	;--- V6C_RELOAD8 ---
.LLo61_3:
	MVI	A, 0
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_ADD16 ---
	MOV	H, B
	MOV	L, C
	DAD	B
	;--- V6C_RELOAD16 ---
.LLo61_1:
	LXI	D, 0
	;--- V6C_BR_CC16 ---
	MOV	A, L
	SUB	E
	MOV	A, H
	SBB	D
	JM	.LBB16_15
; %bb.14:                               ;   in Loop: Header=BB16_13 Depth=1
	;--- V6C_RELOAD8 ---
.LLo61_4:
	MVI	E, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	ADD	E
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_RELOAD16 ---
	XCHG
	LHLD	.LLo61_1+1
	XCHG
	;--- V6C_ADD16 ---
	MOV	A, C
	ADD	E
	MOV	C, A
	MOV	A, B
	ADC	D
	MOV	B, A
.LBB16_15:                              ;   in Loop: Header=BB16_13 Depth=1
	;--- V6C_RELOAD16 ---
.LLo61_2:
	LXI	D, 0
	;--- V6C_BR_CC16 ---
	MOV	A, E
	SUB	L
	MOV	A, D
	SBB	H
	JM	.LBB16_17
; %bb.16:                               ;   in Loop: Header=BB16_13 Depth=1
	;--- V6C_RELOAD8 ---
.LLo61_7:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	ADD	L
	;--- V6C_SPILL8 ---
	STA	.LLo61_6+1
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_2+1
	;--- V6C_ADD16 ---
	DAD	B
	MOV	B, H
	MOV	C, L
.LBB16_17:                              ;   in Loop: Header=BB16_13 Depth=1
	;--- V6C_SPILL16 ---
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	;--- V6C_SPILL8 ---
	STA	.LLo61_3+1
	;--- V6C_RELOAD8 ---
.LLo61_6:
	MVI	L, 0
	;--- V6C_SPILL8 ---
	MOV	B, A
	MOV	A, L
	STA	.LLo61_6+1
	MOV	A, B
	;--- V6C_RELOAD8 ---
	LXI	H, .LLo61_6+1
	MOV	B, M
	CALL	draw_pixel
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	B, 0
	;--- V6C_RELOAD8 ---
.LLo61_8:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_6+1
	CMP	L
	;--- V6C_BRCOND ---
	JNZ	.LBB16_13
; %bb.18:                               ;   in Loop: Header=BB16_13 Depth=1
	;--- V6C_RELOAD8 ---
.LLo61_5:
	MVI	L, 0
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_3+1
	CMP	L
	;--- V6C_BRCOND ---
	JNZ	.LBB16_13
; %bb.19:
	RET
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
	;=== void main(void) ===
; %bb.0:
	LXI	H, 0
.LBB17_1:                               ; =>This Inner Loop Header: Depth=1
	;--- V6C_SPILL16 ---
	SHLD	.LLo61_9+1
	;--- V6C_RELOAD16 ---
.LLo61_9:
	LXI	H, 0
	LXI	D, pos+1
	;--- V6C_DAD ---
	DAD	D
	;--- V6C_LOAD8_P ---
	MOV	B, M
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_9+1
	LXI	D, pos
	;--- V6C_DAD ---
	DAD	D
	;--- V6C_LOAD8_P ---
	MOV	A, M
	CALL	draw_line
	;--- V6C_RELOAD16 ---
	LHLD	.LLo61_9+1
	;--- V6C_INX16 ---
	INX	H
	INX	H
	;--- V6C_BR_CC16_IMM ---
	MVI	A, 0x10
	CMP	L
	JNZ	.LBB17_1
; %bb.3:                                ;   in Loop: Header=BB17_1 Depth=1
	XRA	A
	CMP	H
	JNZ	.LBB17_1
; %bb.2:
	RET
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

	.globl	font                            ; @font
font:
	.ascii	"\000\030$B~BB\000\000|B|BB|\000\000<B@@B<\000\000xDBBDx\000\000~@|@@~\000\000~@|@@@\000\000<B@NB<\000\000BB~BBB"

	.section	.rodata,"a",@progbits
	.globl	BIT_MASK                        ; @BIT_MASK
BIT_MASK:
	.ascii	"\200@ \020\b\004\002\001"

	.data
	.globl	palette                         ; @palette
palette:
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.globl	pos                             ; @pos
pos:
	.ascii	"\377\376\377\372\377\310\377\214\377\177\377d\377(\377\000"

	.addrsig
	.addrsig_sym __mulqi3
	.addrsig_sym __v6c_mulqihi3
	.addrsig_sym __mulhi3
	.addrsig_sym __v6c_udivmod16_body
	.addrsig_sym __udivhi3
	.addrsig_sym __umodhi3
	.addrsig_sym __udivmodhi4
	.addrsig_sym __divmodhi4
	.addrsig_sym __v6c_neg_hl_body
	.addrsig_sym __v6c_neg_de_body
	.addrsig_sym __divhi3
	.addrsig_sym __modhi3
	.addrsig_sym __ashlhi3
	.addrsig_sym __lshrhi3
	.addrsig_sym __ashrhi3
