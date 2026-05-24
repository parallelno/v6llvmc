	.text
	.section	.text.draw_line2,"ax",@progbits
draw_line2:                             ; -- Begin function draw_line2
                                        ; @draw_line2
.Lfunc_begin0:
	;=== void draw_line2(void) ===
	;  [folded: scr_addr_h=-128, x0=127, y0=127, x1=-56, y1=-2]
; %bb.0:
	;DEBUG_VALUE: draw_line2:scr_addr_h <- -128
	;DEBUG_VALUE: draw_line2:x0 <- 127
	;DEBUG_VALUE: draw_line2:y0 <- 127
	;DEBUG_VALUE: draw_line2:x1 <- -56
	;DEBUG_VALUE: draw_line2:y1 <- -2
	;DEBUG_VALUE: draw_line2:_scr_addr_h <- -128
	;DEBUG_VALUE: draw_line2:_x0 <- 127
	;DEBUG_VALUE: draw_line2:_y0 <- 127
	;DEBUG_VALUE: draw_line2:_x1 <- -56
	;DEBUG_VALUE: draw_line2:_y1 <- -2
	MVI	A, 0x80
	MVI	B, 0x7f
	MOV	C, B
	MVI	D, 0xc8
	MVI	E, 0xfe
	;APP
	STA	.ADDR_H+1
	MOV	A, D
	SUB	B
	JC	.L1
	STA	.DX+1
.STRAIGHT_X:
	MOV	A, E
	SUB	C
	JC	.ADV_Y_NEG
.ADV_Y_POS:
	STA	.DY+1
	MVI	A, 0x2c
	STA	.ADV_Y
	JMP	.GET_BIT_MASK
.ADV_Y_NEG:
	CMA

	INR	A
	STA	.DY+1
	MVI	A, 0x2d
	STA	.ADV_Y
.GET_BIT_MASK:
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
	MVI	A, 0
	MOV	E, A
	INR	E
	MOV	B, A
	RRC

	MOV	C, A
.BIT_MASK:
	MVI	D, 0
.LOOP:
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
.ADV_Y:
	INR	L
.NO_ADV_Y:
	MOV	C, A
	DCR	E
	JNZ	.LOOP
.L1:
	RET

.REVERS_X:
	CMA

	INR	A
	STA	.DX+1
	XCHG

	MOV	D, B
	MOV	E, C
	MOV	B, H
	MOV	C, L
	JMP	.STRAIGHT_X

	;NO_APP
	RET
.Lfunc_end0:
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
.Lfunc_begin1:
	;=== void main(void) ===
; %bb.0:
	;DEBUG_VALUE: x <- -56
	;DEBUG_VALUE: y <- -2
	JMP	draw_line2
.Lfunc_end1:
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

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
