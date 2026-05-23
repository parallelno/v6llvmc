	.text
	.section	.text.v6c_set_palette,"ax",@progbits
v6c_set_palette:                        ; -- Begin function v6c_set_palette
                                        ; @v6c_set_palette
.Lfunc_begin0:
	;=== void v6c_set_palette(void) ===
; %bb.0:
	LXI	H, palette+15
	;APP
	HLT

	MVI	A, 0x88
	OUT	0
	MVI	B, 0xf
.Ltmp0:
	MOV	A, B
	OUT	2
	MOV	A, M
	OUT	0xc
	PUSH	PSW
	POP	PSW
	PUSH	PSW
	POP	PSW
	DCX	H
	DCR	B
	OUT	0xc
	JP	.Ltmp0

	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.rand,"ax",@progbits
rand:                                   ; -- Begin function rand
                                        ; @rand
.Lfunc_begin1:
	;=== int rand(void) ===
; %bb.0:
	;APP
.Ltmp1:
	LHLD	__v6c_rand_state
	MOV	A, H
	RAR

	MOV	A, L
	RAR

	XRA	H
	MOV	H, A
	MOV	A, L
	RAR

	MOV	A, H
	RAR

	XRA	L
	MOV	L, A
	XRA	H
	MOV	H, A
	SHLD	__v6c_rand_state

	;NO_APP
	;DEBUG_VALUE: rand:__r <- $hl
	RET
.Lfunc_end1:
                                        ; -- End function
	.section	.text.draw_line2,"ax",@progbits
draw_line2:                             ; -- Begin function draw_line2
                                        ; @draw_line2
.Lfunc_begin2:
	;=== void draw_line2(char x1, char y1) ===
	;  x1 = A
	;  y1 = B
	;  [folded: scr_addr_h=-128, x0=127, y0=127]
; %bb.0:
	;DEBUG_VALUE: draw_line2:x1 <- $a
	;DEBUG_VALUE: draw_line2:y1 <- $b
	;DEBUG_VALUE: draw_line2:_x1 <- $a
	;DEBUG_VALUE: draw_line2:_y1 <- $b
	MOV	E, B
	;DEBUG_VALUE: draw_line2:_y1 <- $e
	;DEBUG_VALUE: draw_line2:y1 <- $e
	MOV	D, A
	;DEBUG_VALUE: draw_line2:_y0 <- 127
	;DEBUG_VALUE: draw_line2:_x0 <- 127
	;DEBUG_VALUE: draw_line2:_scr_addr_h <- -128
	;DEBUG_VALUE: draw_line2:y0 <- 127
	;DEBUG_VALUE: draw_line2:x0 <- 127
	;DEBUG_VALUE: draw_line2:scr_addr_h <- -128
	;DEBUG_VALUE: draw_line2:_x1 <- $d
	;DEBUG_VALUE: draw_line2:x1 <- $d
	MVI	A, 0x80
	MVI	B, 0x7f
	MOV	C, B
	;APP
	STA	.ADDR_H+1
	MOV	A, D
	SUB	B
	STA	.DX+1
	JC	.L1
	MOV	A, E
	SUB	C
	STA	.DY+1
	JC	.L1
	LXI	H, BIT_MASK
	MVI	A, 7
	ANA	B
	MOV	E, A
	MVI	D, 0
	DAD	D
	MOV	A, M
	STA	.BIT_MASK+1
	MVI	A, 0xf8
	ANA	B
	RRC

	RRC

	RRC

.ADDR_H:
	ADI	0x80
	MOV	H, A
	MOV	L, C
.DX:
	MVI	B, 0
	MOV	C, B
	MOV	E, B
	INR	E
.BIT_MASK:
	MVI	D, 0
.L0:
	MOV	A, M
	ORA	D
	MOV	M, A
	MOV	A, D
	RRC

	MOV	D, A
	JNC	.NO_ADV_X
	INR	H
.NO_ADV_X:
	MOV	A, C
.DY:
	SUI	0
	JNC	.NO_ADV_Y
	ADD	B
	INR	L
.NO_ADV_Y:
	MOV	C, A
	DCR	E
	JNZ	.L0
.L1:
	RET

	;NO_APP
	RET
.Lfunc_end2:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin3:
	;=== void main(void) ===
; %bb.0:
	;APP
	MVI	A, 0xfb
	STA	0x38
	MVI	A, 0xc9
	STA	0x39

	;NO_APP
	;APP
	EI

	;NO_APP
	CALL	v6c_set_palette
	MVI	A, 0x64
	;DEBUG_VALUE: i <- 0
.LBB18_1:                               ; =>This Inner Loop Header: Depth=1
	;DEBUG_VALUE: i <- undef
	;--- V6C_SPILL8 ---
	STA	.LLo61_1+1
	CALL	rand
	;DEBUG_VALUE: lo <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	;DEBUG_VALUE: r <- $hl
	LXI	D, 0xff
	;--- V6C_AND16 ---
	MOV	A, L
	ANA	E
	MOV	E, A
	MOV	A, H
	ANA	D
	MOV	D, A
	;--- V6C_CMP16_IMM ---
	MVI	A, 0xf9
	SUB	E
	MVI	A, 0
	SBB	D
	LXI	B, 0xfa
	;--- V6C_SPILL16 ---
	PUSH	H
	MOV	L, C
	MOV	H, B
	SHLD	.LLo61_0+1
	POP	H
	JC	.LBB18_3
; %bb.2:                                ;   in Loop: Header=BB18_1 Depth=1
	;--- V6C_SPILL16 ---
	XCHG
	SHLD	.LLo61_0+1
	XCHG
.LBB18_3:                               ;   in Loop: Header=BB18_1 Depth=1
	;--- V6C_SRL16 ---
	MOV	L, H
	MVI	H, 0
	;DEBUG_VALUE: hi <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	;--- V6C_CMP16_IMM ---
	MVI	A, 0xf9
	SUB	L
	MOV	A, H
	SBB	H
	;--- V6C_RELOAD8 ---
.LLo61_1:
	MVI	A, 0
	LXI	D, 0xfa
	JC	.LBB18_5
; %bb.4:                                ;   in Loop: Header=BB18_1 Depth=1
	;DEBUG_VALUE: hi <- [DW_OP_LLVM_convert 16 7, DW_OP_LLVM_convert 8 7, DW_OP_stack_value] $hl
	XCHG
.LBB18_5:                               ;   in Loop: Header=BB18_1 Depth=1
	MOV	A, E
	ADI	3
	;DEBUG_VALUE: x <- $a
	MOV	E, A
	;DEBUG_VALUE: x <- $e
	;--- V6C_RELOAD16 ---
.LLo61_0:
	LXI	H, 0
	MOV	A, L
	ADI	3
	;DEBUG_VALUE: y <- $a
	MOV	B, A
	;DEBUG_VALUE: y <- $b
	MOV	A, E
	CALL	draw_line2
	;DEBUG_VALUE: i <- undef
	;--- V6C_RELOAD8 ---
	LDA	.LLo61_1+1
	DCR	A
	;--- V6C_BRCOND ---
	JNZ	.LBB18_1
; %bb.6:
	RET
.Lfunc_end3:
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
	.addrsig_sym palette
