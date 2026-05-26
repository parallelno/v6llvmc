	.text
	.section	.text.v6c_set_palette,"ax",@progbits
v6c_set_palette:                        ; -- Begin function v6c_set_palette
                                        ; @v6c_set_palette
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
                                        ; -- End function
	.section	.text.memset,"ax",@progbits
memset:                                 ; -- Begin function memset
                                        ; @memset
; %bb.0:
	LXI	H, 0x8000
.LBB16_1:                               ; =>This Inner Loop Header: Depth=1
	MVI	M, 0
	INX	H
	MOV	A, H
	ORA	L
	JNZ	.LBB16_1
; %bb.2:
	RET
                                        ; -- End function
	.section	.text.rand,"ax",@progbits
rand:                                   ; -- Begin function rand
                                        ; @rand
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
	RET
                                        ; -- End function
	.section	.text.draw_line,"ax",@progbits
draw_line:                              ; -- Begin function draw_line
                                        ; @draw_line
; %bb.0:
	MOV	E, B
	MOV	D, A
	MVI	A, 0x80
	MVI	B, 0x7f
	MOV	C, B
	;APP
	STA	.ADDR_H+1
	MOV	A, D
	SUB	B
	JC	.SWAP_POINTS
.SET_DX:
	MOV	D, A
	LXI	H, .ADV_Y
	MOV	A, E
	SUB	C
	JC	.ADV_Y_NEG
.ADV_Y_POS:
	MVI	M, 0x2c
	JMP	.CHECK_SLOP
.ADV_Y_NEG:
	CMA

	INR	A
	MVI	M, 0x2d
.CHECK_SLOP:
	CMP	D
	JNC	.VERTICAL_DRAW
	STA	.DY+1
	CALL	.SET_LOOP_VARS
.LOOP_H:
	MOV	A, M
	ORA	E
	MOV	M, A
	ANA	E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
	MOV	A, C
.DY:
	SUI	0
	JNC	.NO_ADV_Y
	ADD	D
.ADV_Y:
	INR	L
.NO_ADV_Y:
	MOV	C, A
	DCR	B
	JNZ	.LOOP_H
	RET

.SWAP_POINTS:
	CMA

	INR	A
	XCHG

	MOV	D, B
	MOV	E, C
	MOV	B, H
	MOV	C, L
	JMP	.SET_DX
.VERTICAL_DRAW:
	LXI	H, .DX2+1
	MOV	M, D
	MOV	D, A
	LDA	.ADV_Y
	STA	.ADV_Y2
	CALL	.SET_LOOP_VARS
.LOOP_V:
	MOV	A, M
	ORA	E
	MOV	M, A
.ADV_Y2:
	INR	L
	MOV	A, C
.DX2:
	SUI	0
	MOV	C, A
	JNC	.NO_ADV_X2
	ADD	D
	MOV	C, A
	MOV	A, E
	RRC

	MOV	E, A
	ADC	H
	SUB	E
	MOV	H, A
.NO_ADV_X2:
	DCR	B
	JNZ	.LOOP_V
	RET

.SET_LOOP_VARS:
	LXI	H, BIT_MASK
	MVI	A, 7
	ANA	B
	ADD	L
	MOV	L, A
	ADC	H
	SUB	L
	MOV	H, A
	MOV	E, M
	MVI	A, 0xf8
	ANA	B
	RRC

	RRC

	RRC

.ADDR_H:
	ADI	0x80
	MOV	H, A
	MOV	L, C
	MOV	B, D
	INR	B
	XRA	A
	ORA	D
	RAR

	MOV	C, A
	RET


	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_pixel,"ax",@progbits
draw_pixel:                             ; -- Begin function draw_pixel
                                        ; @draw_pixel
; %bb.0:
	MOV	L, B
	;APP
	MOV	C, A
	RRC

	RRC

	RRC

	ANI	0x1f
	ADI	0x80
	MOV	H, A
	MVI	A, 7
	ANA	C
	LXI	B, BIT_MASK
	ADD	C
	MOV	C, A
	ADC	B
	SUB	C
	MOV	B, A
	LDAX	B
	ORA	M
	MOV	M, A

	;NO_APP
	RET
                                        ; -- End function
	.section	.text.draw_circle,"ax",@progbits
draw_circle:                            ; -- Begin function draw_circle
                                        ; @draw_circle
; %bb.0:
	MOV	D, A
	XRA	A
	MOV	H, A
	MVI	E, 0x7f
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, D
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
	MOV	A, H
	ORA	A
	RAR
	MOV	H, A
	MOV	A, L
	RAR
	MOV	L, A
                                        ; kill: def $l killed $l killed $hl
	MOV	A, L
	STA	.LLo61_3+1
	MOV	A, D
	MVI	L, 0
.LBB20_1:                               ; =>This Inner Loop Header: Depth=1
	MOV	B, A
	MOV	A, L
	STA	.LLo61_4+1
	MOV	A, B
	MOV	A, E
	STA	.LLo61_6+1
	MOV	A, B
	MOV	E, A
	ADI	0x7f
	MOV	D, A
	MOV	A, L
	ADI	0x7f
	STA	.LLo61_0+1
	STA	.LLo61_1+1
	LXI	H, .LLo61_2+1
	MOV	M, E
	MOV	A, D
.LLo61_0:
	MVI	B, 0
	CALL	draw_pixel
	MOV	A, E
.LLo61_6:
	MVI	E, 0
	XRI	0x7f
	STA	.LLo61_5+1
.LLo61_1:
	MVI	B, 0
	CALL	draw_pixel
	MOV	A, D
	MOV	B, E
	CALL	draw_pixel
	LDA	.LLo61_5+1
	MOV	B, E
	CALL	draw_pixel
	LDA	.LLo61_0+1
	MOV	B, D
	CALL	draw_pixel
	MOV	A, E
	MOV	B, D
	CALL	draw_pixel
	LDA	.LLo61_0+1
.LLo61_5:
	MVI	D, 0
	MOV	B, D
	CALL	draw_pixel
	MOV	A, E
	MOV	B, D
	CALL	draw_pixel
.LLo61_4:
	MVI	L, 0
	INR	L
	MOV	A, L
	STA	.LLo61_4+1
.LLo61_3:
	MVI	A, 0
	ADD	L
.LLo61_2:
	MVI	L, 0
	MVI	D, 0
	MOV	H, D
	STA	.LLo61_3+1
	MOV	C, A
	MOV	A, C
	SUB	L
	MOV	L, A
	MOV	A, D
	SBB	H
	MOV	H, A
	MVI	A, 0xff
	SUB	L
	MVI	A, 0xff
	SBB	H
	JP	.LBB20_3
; %bb.2:                                ;   in Loop: Header=BB20_1 Depth=1
	MOV	A, L
	STA	.LLo61_3+1
.LBB20_3:                               ;   in Loop: Header=BB20_1 Depth=1
	MVI	L, 0
	JP	.LBB20_5
; %bb.4:                                ;   in Loop: Header=BB20_1 Depth=1
	MVI	L, 1
.LBB20_5:                               ;   in Loop: Header=BB20_1 Depth=1
	LDA	.LLo61_2+1
	SUB	L
	DCR	E
	LXI	H, .LLo61_4+1
	MOV	L, M
	CMP	L
	JNC	.LBB20_1
; %bb.6:
	RET
                                        ; -- End function
	.section	.text.main,"ax",@progbits
	.globl	main                            ; -- Begin function main
main:                                   ; @main
; %bb.0:
	PUSH	PSW
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
	CALL	memset
	MVI	A, 0x64
.LBB21_1:                               ; =>This Inner Loop Header: Depth=1
	LXI	H, 1
	DAD	SP
	MOV	M, A
	CALL	rand
	MOV	A, L
	MOV	B, H
	CALL	draw_line
	LXI	H, 1
	DAD	SP
	MOV	A, M
	DCR	A
	JNZ	.LBB21_1
; %bb.3:
	MVI	H, 0xa
	MVI	A, 0x64
.LBB21_4:                               ; =>This Inner Loop Header: Depth=1
	PUSH	H
	LXI	H, 3
	DAD	SP
	MOV	M, A
	POP	H
	XCHG
	LXI	H, 0
	DAD	SP
	MOV	M, D
	XCHG
	PUSH	H
	LXI	H, 3
	DAD	SP
	MOV	A, M
	POP	H
	CALL	draw_circle
	MOV	D, L
	LXI	H, 0
	DAD	SP
	MOV	H, M
	MOV	L, D
	PUSH	H
	LXI	H, 3
	DAD	SP
	MOV	A, M
	POP	H
	ADI	0xf6
	DCR	H
	JNZ	.LBB21_4
; %bb.2:
	POP	PSW
	RET
                                        ; -- End function
	.data
	.globl	__v6c_rand_state                ; @__v6c_rand_state
__v6c_rand_state:
	DW	1                               ; 0x1

palette:                                ; @palette
	.ascii	"\000\021\"3DUfw\210\231\252\273\314\335\356\377"

	.section	.rodata,"a",@progbits
BIT_MASK:                               ; @BIT_MASK
	.ascii	"\200@ \020\b\004\002\001"

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
	.addrsig_sym BIT_MASK
